defmodule Admin.Chatbot.PdfExtractorTest do
  # runs the real pdftotext (poppler), installed in CI and the Docker image
  use ExUnit.Case, async: true

  alias Admin.Chatbot.PdfExtractor

  @fixtures Path.expand("../../fixtures/chatbot", __DIR__)

  test "extracts the text and counts the pages" do
    assert {:ok, %{text: text, pages: 2}} =
             PdfExtractor.extract(Path.join(@fixtures, "two_pages.pdf"))

    assert text =~ "Photosynthesis is the process"
    assert text =~ "The Calvin cycle then fixes carbon dioxide"
    refute text =~ "\f"
  end

  test "rejects a PDF without selectable text" do
    assert {:error, :no_text} = PdfExtractor.extract(Path.join(@fixtures, "no_text.pdf"))
  end

  @tag :capture_log
  test "fails on a file that isn't a PDF" do
    path = Path.join(System.tmp_dir!(), "not-a-pdf-#{System.unique_integer([:positive])}.pdf")
    File.write!(path, "definitely not a pdf")
    on_exit(fn -> File.rm(path) end)

    assert {:error, :extraction_failed} = PdfExtractor.extract(path)
  end
end
