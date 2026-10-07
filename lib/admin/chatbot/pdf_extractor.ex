defmodule Admin.Chatbot.PdfExtractor do
  @moduledoc """
  Extracts the text of a PDF with poppler's `pdftotext` (installed in the
  runtime image, `brew install poppler` locally).

  PDFs with (almost) no selectable text — typically scans — are rejected
  rather than OCR'd: below `@min_chars_per_page` non-whitespace characters
  per page on average, extraction returns `{:error, :no_text}`.
  """

  require Logger

  @timeout 30_000
  @min_chars_per_page 100

  @type result :: %{text: String.t(), pages: pos_integer()}

  @spec extract(path :: String.t()) ::
          {:ok, result()} | {:error, :no_text | :extractor_unavailable | :extraction_failed}
  def extract(path) do
    case System.find_executable("pdftotext") do
      nil ->
        Logger.error("Admin.Chatbot.PdfExtractor: pdftotext is not installed")
        {:error, :extractor_unavailable}

      executable ->
        run(executable, path)
    end
  end

  # runs in a supervised task so a pathological PDF can't block the caller
  # (the LiveView) past the timeout
  defp run(executable, path) do
    task =
      Task.Supervisor.async_nolink(Admin.TaskSupervisor, fn ->
        System.cmd(executable, ["-layout", "-enc", "UTF-8", path, "-"])
      end)

    case Task.yield(task, @timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, {output, 0}} ->
        parse(output)

      {:ok, {_output, status}} ->
        Logger.warning("Admin.Chatbot.PdfExtractor: pdftotext exited with #{status}")
        {:error, :extraction_failed}

      {:exit, reason} ->
        Logger.error("Admin.Chatbot.PdfExtractor: pdftotext crashed: #{inspect(reason)}")
        {:error, :extraction_failed}

      nil ->
        Logger.warning("Admin.Chatbot.PdfExtractor: pdftotext timed out")
        {:error, :extraction_failed}
    end
  end

  # pdftotext ends every page with a form feed
  defp parse(output) do
    pages = max(length(String.split(output, "\f")) - 1, 1)
    text = normalize(output)
    visible_chars = text |> String.replace(~r/\s/u, "") |> String.length()

    if visible_chars / pages < @min_chars_per_page do
      {:error, :no_text}
    else
      {:ok, %{text: text, pages: pages}}
    end
  end

  # `-layout` pads columns with runs of spaces, which would only cost tokens;
  # null bytes can't be stored in a jsonb column
  defp normalize(output) do
    output
    |> String.replace(<<0>>, "")
    |> String.replace("\f", "\n\n")
    |> String.split("\n")
    |> Enum.map_join("\n", fn line -> line |> String.replace(~r/[ \t]+/, " ") |> String.trim() end)
    |> String.replace(~r/\n{3,}/, "\n\n")
    |> String.trim()
  end
end
