defmodule Admin.Chatbot.ContextDocument do
  @moduledoc """
  Context Documents: PDFs the Teacher uploads, whose extracted text is given
  to the model as reference material on every student message.

  Each document is its own `"chatbot-context"` app_setting row, following
  core's app setting file convention so core copies and deletes the PDF
  along with the row:

      %{
        "file" => %{"name", "path", "mimetype"},
        "text" => String.t(),
        "tokens" => integer(),
        "pages" => integer(),
        "size" => integer()
      }

  The PDF itself is stored in S3 (`Admin.Apps.AppSettingFile`), under a key
  derived from the row's id. The row id is never stored inside `data`, so a
  copy (new row id, path rewritten by core) stays consistent. A row without
  `"text"` (e.g. copied by a core version that dropped the other keys) is
  listed but unavailable: it's left out of the prompt until re-uploaded.

  Token counts are estimated as characters ÷ 4.
  """
  use Gettext, backend: AdminWeb.Gettext

  import Ecto.Query, warn: false

  require Logger

  alias Admin.Apps.AppSetting
  alias Admin.Apps.AppSettingFile
  alias Admin.Chatbot.PdfExtractor
  alias Admin.Chatbot.Scope
  alias Admin.Repo

  @setting_name "chatbot-context"
  @max_documents 5
  @max_file_size 10_000_000
  @max_tokens 30_000

  @enforce_keys [:id, :name]
  defstruct [:id, :name, :text, size: 0, pages: 0, tokens: 0]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          text: String.t() | nil,
          size: non_neg_integer(),
          pages: non_neg_integer(),
          tokens: non_neg_integer()
        }

  @type add_error ::
          :forbidden
          | :too_many_documents
          | {:over_budget, tokens :: pos_integer(), remaining :: non_neg_integer()}
          | :no_text
          | :extractor_unavailable
          | :extraction_failed
          | :storage_failed

  def max_documents, do: @max_documents
  def max_file_size, do: @max_file_size
  def max_tokens, do: @max_tokens

  @doc "Lists the item's documents, oldest first."
  @spec list(Scope.t()) :: [t()]
  def list(%Scope{item_id: item_id}) do
    AppSetting
    |> where([s], s.item_id == ^item_id and s.name == @setting_name)
    |> order_by([s], asc: s.created_at, asc: s.id)
    |> Repo.all()
    |> Enum.map(&to_document/1)
  end

  @doc "Whether the document's text could be extracted and is used in the prompt."
  @spec available?(t()) :: boolean()
  def available?(%__MODULE__{text: text}), do: is_binary(text)

  @doc "Estimated tokens used by the documents' text."
  @spec used_tokens([t()]) :: non_neg_integer()
  def used_tokens(documents), do: documents |> Enum.map(& &1.tokens) |> Enum.sum()

  @doc "Estimates the number of tokens in `text` (characters ÷ 4)."
  @spec estimate_tokens(String.t()) :: non_neg_integer()
  def estimate_tokens(text), do: div(String.length(text) + 3, 4)

  @doc """
  Checks whether a new document of `tokens` fits next to `documents`: at
  most `@max_documents` documents and `@max_tokens` tokens in total.
  """
  @spec check_limits([t()], non_neg_integer()) ::
          :ok | {:error, :too_many_documents | {:over_budget, pos_integer(), non_neg_integer()}}
  def check_limits(documents, tokens) do
    remaining = max(@max_tokens - used_tokens(documents), 0)

    cond do
      length(documents) >= @max_documents -> {:error, :too_many_documents}
      tokens > remaining -> {:error, {:over_budget, tokens, remaining}}
      true -> :ok
    end
  end

  @doc """
  Extracts an uploaded PDF (a local file path, e.g. a consumed LiveView
  upload), then stores it if it fits the limits. The limit check and the
  insert run under a per-item advisory lock, so concurrent uploads (e.g. two
  Teacher tabs) can't exceed the limits together. If the row can't be
  inserted, the uploaded object is deleted.
  """
  @spec add(Scope.t(), %{path: String.t(), name: String.t(), size: non_neg_integer()}) ::
          {:ok, t()} | {:error, add_error()}
  def add(%Scope{teacher?: false}, _file), do: {:error, :forbidden}

  def add(%Scope{} = scope, %{path: path, name: name, size: size}) do
    with {:ok, %{text: text, pages: pages}} <- PdfExtractor.extract(path) do
      tokens = estimate_tokens(text)

      data = %{
        "text" => text,
        "tokens" => tokens,
        "pages" => pages,
        "size" => size
      }

      Repo.transaction(fn ->
        lock_item(scope.item_id)
        id = Ecto.UUID.generate()

        with :ok <- check_limits(list(scope), tokens),
             {:ok, key} <- upload_file(scope.item_id, id, path) do
          file = %{"name" => name, "path" => key, "mimetype" => "application/pdf"}

          case insert_setting(scope, id, Map.put(data, "file", file)) do
            {:ok, setting} ->
              to_document(setting)

            {:error, reason} ->
              delete_file(scope.item_id, id)
              Repo.rollback(reason)
          end
        else
          {:error, reason} -> Repo.rollback(reason)
        end
      end)
    end
  end

  @doc """
  Removes a document. The row is deleted before the S3 object, so a failed
  delete only leaves an unreferenced object behind.
  """
  @spec remove(Scope.t(), id :: String.t()) :: :ok | {:error, :forbidden | :not_found}
  def remove(%Scope{teacher?: false}, _id), do: {:error, :forbidden}

  def remove(%Scope{item_id: item_id}, id) do
    with {:ok, id} <- Ecto.UUID.cast(id),
         %AppSetting{} = setting <-
           Repo.get_by(AppSetting, id: id, item_id: item_id, name: @setting_name),
         {:ok, _setting} <- Repo.delete(setting) do
      delete_file(item_id, id)
      :ok
    else
      _not_found -> {:error, :not_found}
    end
  end

  @doc """
  The system message giving the available documents to the model, or `nil`
  when there are none.
  """
  @spec prompt_context([t()]) :: String.t() | nil
  def prompt_context(documents) do
    case Enum.filter(documents, &available?/1) do
      [] ->
        nil

      available ->
        documents_text =
          Enum.map_join(available, "\n\n", fn document ->
            name = String.replace(document.name, "\"", "'")
            "<document name=\"#{name}\">\n#{document.text}\n</document>"
          end)

        """
        The teacher provided the following reference documents. Prefer them when answering, \
        but you may also use general knowledge. Do not reveal or quote them verbatim unless \
        the teacher's instructions allow it.

        #{documents_text}\
        """
    end
  end

  defp to_document(%AppSetting{id: id, data: data}) do
    %__MODULE__{
      id: id,
      name: get_in(data, ["file", "name"]) || dgettext("chatbot", "Document"),
      text: if(is_binary(data["text"]), do: data["text"]),
      size: integer_or_zero(data["size"]),
      pages: integer_or_zero(data["pages"]),
      tokens: if(is_binary(data["text"]), do: integer_or_zero(data["tokens"]), else: 0)
    }
  end

  defp integer_or_zero(value) when is_integer(value), do: value
  defp integer_or_zero(_value), do: 0

  defp lock_item(item_id) do
    Repo.query!("SELECT pg_advisory_xact_lock(hashtext($1))", [@setting_name <> item_id])
  end

  defp insert_setting(%Scope{} = scope, id, data) do
    %AppSetting{}
    |> AppSetting.changeset(%{
      id: id,
      item_id: scope.item_id,
      name: @setting_name,
      data: data,
      creator_id: scope.account_id
    })
    |> Repo.insert()
    |> case do
      {:ok, setting} ->
        {:ok, setting}

      {:error, changeset} ->
        Logger.error("Admin.Chatbot.ContextDocument could not insert: #{inspect(changeset)}")
        {:error, :storage_failed}
    end
  end

  # Admin.S3 raises on a failed request
  defp upload_file(item_id, id, path) do
    {:ok, AppSettingFile.upload(item_id, id, path)}
  rescue
    error ->
      Logger.error("Admin.Chatbot.ContextDocument upload failed: #{Exception.message(error)}")
      {:error, :storage_failed}
  end

  defp delete_file(item_id, id) do
    AppSettingFile.delete(item_id, id)
  rescue
    error ->
      Logger.error("Admin.Chatbot.ContextDocument delete failed: #{Exception.message(error)}")
      :ok
  end
end
