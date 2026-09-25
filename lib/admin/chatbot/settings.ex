defmodule Admin.Chatbot.Settings do
  @moduledoc """
  Chatbot Settings: the Teacher's configuration of a chatbot item — its
  name, System Prompt, Cue, Starter Suggestions and avatar.

  Everything about how they're stored stays in here: they live in two
  `app_setting` rows, in the camelCase format the React app wrote so
  existing items keep working:

    * `"chatbot-prompt"` — `%{"chatbotName", "initialPrompt", "chatbotCue",
      "starterSuggestions" => [String.t()]}`
    * `"chatbot-avatar"` — `%{"file" => %{"name", "path", "mimetype"}}`, the
      image itself in S3 via `Admin.Apps.AppSettingFile`. That row is the
      source of truth for "is an avatar configured", not S3.

  Reads return a resolved `%Settings{}`: a blank name falls back to the
  translated default, a blank Cue is `nil` (no Cue), and the avatar is a
  signed URL. Writes are only allowed for a Teacher scope, and return
  `{:error, :forbidden}` otherwise.
  """
  use Ecto.Schema
  use Gettext, backend: AdminWeb.Gettext

  import Ecto.Changeset, except: [change: 2]

  require Logger

  alias Admin.Apps.AppSetting
  alias Admin.Apps.AppSettingFile
  alias Admin.Chatbot.Scope
  alias Admin.Chatbot.Settings.StarterSuggestion
  alias Admin.Repo

  @prompt_setting "chatbot-prompt"
  @avatar_setting "chatbot-avatar"

  @primary_key false
  embedded_schema do
    field :name, :string
    field :system_prompt, :string
    field :cue, :string
    field :avatar_url, :string

    embeds_many :starter_suggestions, StarterSuggestion, on_replace: :delete
  end

  @type t :: %__MODULE__{}

  @doc "Loads the item's settings, with defaults applied."
  @spec load(Scope.t()) :: t()
  def load(%Scope{item_id: item_id}) do
    data =
      case get_setting(item_id, @prompt_setting) do
        nil -> %{}
        %AppSetting{data: data} -> data
      end

    %__MODULE__{
      name: blank_to_nil(data["chatbotName"]) || dgettext("chatbot", "Chatbot"),
      system_prompt: blank_to_nil(data["initialPrompt"]),
      cue: blank_to_nil(data["chatbotCue"]),
      starter_suggestions:
        for(
          value <- List.wrap(data["starterSuggestions"]),
          is_binary(value),
          do: %StarterSuggestion{value: value}
        ),
      avatar_url: avatar_url(item_id)
    }
  end

  @doc """
  Changeset backing the Teacher's settings form. Starter Suggestion rows are
  added/removed through `inputs_for` with the `starter_suggestions_sort` and
  `starter_suggestions_drop` params.
  """
  @spec change(t(), map()) :: Ecto.Changeset.t()
  def change(%__MODULE__{} = settings, attrs \\ %{}) do
    settings
    |> cast(attrs, [:name, :system_prompt, :cue])
    |> cast_embed(:starter_suggestions,
      with: &StarterSuggestion.changeset/2,
      sort_param: :starter_suggestions_sort,
      drop_param: :starter_suggestions_drop
    )
    |> validate_required([:name, :system_prompt])
  end

  @doc """
  Validates and stores the form params, dropping empty Starter Suggestions.
  Returns the reloaded settings, the invalid changeset, `:forbidden` for a
  non-Teacher, or `:storage_failed` if the row couldn't be written.
  """
  @spec save(Scope.t(), map()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t() | :forbidden | :storage_failed}
  def save(%Scope{teacher?: false}, _attrs), do: {:error, :forbidden}

  def save(%Scope{} = scope, attrs) do
    with {:ok, settings} <- %__MODULE__{} |> change(attrs) |> apply_action(:update),
         {:ok, _setting} <- upsert_data(scope, @prompt_setting, to_data(settings)) do
      {:ok, load(scope)}
    end
  end

  @doc """
  Stores an uploaded image (a local file path, e.g. a consumed LiveView
  upload) as the avatar. The avatar row is created first so its id — which
  the S3 key derives from — is stable across retries; its data only points
  at the file once the upload succeeded.
  """
  @spec put_avatar(Scope.t(), %{path: String.t(), name: String.t(), mimetype: String.t()}) ::
          {:ok, t()} | {:error, :forbidden | :storage_failed}
  def put_avatar(%Scope{teacher?: false}, _file), do: {:error, :forbidden}

  def put_avatar(%Scope{} = scope, %{path: path, name: name, mimetype: mimetype}) do
    with {:ok, setting} <- get_or_create_setting(scope, @avatar_setting),
         {:ok, key} <- upload_file(scope.item_id, setting.id, path),
         {:ok, _setting} <-
           update_data(setting, %{
             "file" => %{"name" => name, "path" => key, "mimetype" => mimetype}
           }) do
      {:ok, load(scope)}
    end
  end

  @doc """
  Removes the avatar. The row is cleared before the S3 object is deleted, so
  a failed delete only leaves an unreferenced object behind.
  """
  @spec remove_avatar(Scope.t()) :: {:ok, t()} | {:error, :forbidden | :storage_failed}
  def remove_avatar(%Scope{teacher?: false}), do: {:error, :forbidden}

  def remove_avatar(%Scope{item_id: item_id} = scope) do
    case get_setting(item_id, @avatar_setting) do
      nil ->
        {:ok, load(scope)}

      setting ->
        with {:ok, _setting} <- update_data(setting, %{}) do
          delete_file(item_id, setting.id)
          {:ok, load(scope)}
        end
    end
  end

  defp to_data(%__MODULE__{} = settings) do
    %{
      "chatbotName" => settings.name,
      "initialPrompt" => settings.system_prompt,
      "chatbotCue" => settings.cue,
      "starterSuggestions" =>
        for(%{value: value} <- settings.starter_suggestions, value not in [nil, ""], do: value)
    }
  end

  defp avatar_url(item_id) do
    case get_setting(item_id, @avatar_setting) do
      %AppSetting{data: %{"file" => %{"path" => path}}} -> AppSettingFile.url(path)
      _no_avatar -> nil
    end
  end

  defp blank_to_nil(value) when is_binary(value) do
    if String.trim(value) == "", do: nil, else: value
  end

  defp blank_to_nil(_value), do: nil

  # at most one row per {item_id, name}, mirroring how the React app treats
  # app settings as a keyed map
  defp get_setting(item_id, name), do: Repo.get_by(AppSetting, item_id: item_id, name: name)

  defp get_or_create_setting(%Scope{} = scope, name) do
    case get_setting(scope.item_id, name) do
      nil -> insert_setting(scope, name, %{})
      setting -> {:ok, setting}
    end
  end

  defp upsert_data(%Scope{} = scope, name, data) do
    case get_setting(scope.item_id, name) do
      nil -> insert_setting(scope, name, data)
      setting -> update_data(setting, data)
    end
  end

  defp insert_setting(%Scope{} = scope, name, data) do
    %AppSetting{}
    |> AppSetting.changeset(%{
      item_id: scope.item_id,
      name: name,
      data: data,
      creator_id: scope.account_id
    })
    |> Repo.insert()
    |> storage_result()
  end

  defp update_data(%AppSetting{} = setting, data) do
    setting
    |> AppSetting.changeset(%{data: data})
    |> Repo.update()
    |> storage_result()
  end

  defp storage_result({:ok, setting}), do: {:ok, setting}

  defp storage_result({:error, changeset}) do
    Logger.error("Admin.Chatbot.Settings could not write app_setting: #{inspect(changeset)}")
    {:error, :storage_failed}
  end

  # Admin.S3 raises on a failed request; turned into an error tuple here so
  # a failed upload surfaces as a flash instead of crashing the LiveView
  defp upload_file(item_id, setting_id, path) do
    {:ok, AppSettingFile.upload(item_id, setting_id, path)}
  rescue
    error ->
      Logger.error("Admin.Chatbot.Settings avatar upload failed: #{Exception.message(error)}")
      {:error, :storage_failed}
  end

  defp delete_file(item_id, setting_id) do
    AppSettingFile.delete(item_id, setting_id)
  rescue
    error ->
      Logger.error("Admin.Chatbot.Settings avatar delete failed: #{Exception.message(error)}")
      :ok
  end
end
