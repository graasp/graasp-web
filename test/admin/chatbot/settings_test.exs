defmodule Admin.Chatbot.SettingsTest do
  use Admin.DataCase

  # the storage-failure tests log the (expected) S3 errors
  @moduletag :capture_log

  import Mox
  import Admin.AccountsFixtures
  import Admin.ItemsFixtures

  alias Admin.Apps.AppSetting
  alias Admin.Chatbot.Scope
  alias Admin.Chatbot.Settings

  setup :verify_on_exit!

  setup do
    item = item_fixture(user_scope_fixture())
    teacher = %Scope{item_id: item.id, account_id: item.creator_id, teacher?: true}
    student = %{teacher | teacher?: false}
    %{item: item, teacher: teacher, student: student}
  end

  defp setting(item_id, name), do: Repo.get_by(AppSetting, item_id: item_id, name: name)

  defp insert_setting(scope, name, data) do
    Repo.insert!(%AppSetting{
      item_id: scope.item_id,
      creator_id: scope.account_id,
      name: name,
      data: data
    })
  end

  describe "load/1" do
    test "applies defaults when nothing is configured", %{teacher: teacher} do
      assert %Settings{
               name: "Chatbot",
               system_prompt: nil,
               cue: nil,
               starter_suggestions: [],
               avatar_url: nil
             } = Settings.load(teacher)
    end

    test "reads a row written by the React app", %{teacher: teacher} do
      insert_setting(teacher, "chatbot-prompt", %{
        "chatbotName" => "Ada",
        "initialPrompt" => "Be concise.",
        "chatbotCue" => "Hello!",
        "starterSuggestions" => ["What is this?", "Help me"]
      })

      settings = Settings.load(teacher)

      assert settings.name == "Ada"
      assert settings.system_prompt == "Be concise."
      assert settings.cue == "Hello!"
      assert Enum.map(settings.starter_suggestions, & &1.value) == ["What is this?", "Help me"]
    end

    test "treats a blank name and cue as unset", %{teacher: teacher} do
      insert_setting(teacher, "chatbot-prompt", %{"chatbotName" => " ", "chatbotCue" => ""})

      assert %Settings{name: "Chatbot", cue: nil} = Settings.load(teacher)
    end
  end

  describe "save/2" do
    test "writes the React-compatible format and drops empty suggestions", %{teacher: teacher} do
      params = %{
        "name" => "Ada",
        "system_prompt" => "Be concise.",
        "cue" => "",
        "starter_suggestions" => %{"0" => %{"value" => "Hi"}, "1" => %{"value" => ""}}
      }

      assert {:ok, settings} = Settings.save(teacher, params)
      assert settings.name == "Ada"
      assert settings.cue == nil
      assert Enum.map(settings.starter_suggestions, & &1.value) == ["Hi"]

      assert setting(teacher.item_id, "chatbot-prompt").data == %{
               "chatbotName" => "Ada",
               "initialPrompt" => "Be concise.",
               "chatbotCue" => nil,
               "starterSuggestions" => ["Hi"]
             }
    end

    test "round-trips a React row unchanged", %{teacher: teacher} do
      data = %{
        "chatbotName" => "Ada",
        "initialPrompt" => "Be concise.",
        "chatbotCue" => "Hello!",
        "starterSuggestions" => ["What is this?"]
      }

      insert_setting(teacher, "chatbot-prompt", data)

      params = teacher |> Settings.load() |> form_params()

      assert {:ok, _settings} = Settings.save(teacher, params)
      assert setting(teacher.item_id, "chatbot-prompt").data == data
    end

    test "removing every suggestion row empties the list", %{teacher: teacher} do
      insert_setting(teacher, "chatbot-prompt", %{
        "chatbotName" => "Ada",
        "initialPrompt" => "Be concise.",
        "starterSuggestions" => ["Hi"]
      })

      params = %{
        "name" => "Ada",
        "system_prompt" => "Be concise.",
        "starter_suggestions" => %{"0" => %{"value" => "Hi"}},
        "starter_suggestions_drop" => ["0"]
      }

      assert {:ok, %Settings{starter_suggestions: []}} = Settings.save(teacher, params)
    end

    test "rejects missing name or system prompt", %{teacher: teacher} do
      assert {:error, %Ecto.Changeset{} = changeset} =
               Settings.save(teacher, %{"name" => "", "system_prompt" => ""})

      assert %{name: [_], system_prompt: [_]} = errors_on(changeset)
      refute setting(teacher.item_id, "chatbot-prompt")
    end

    test "is forbidden for a student", %{student: student} do
      assert {:error, :forbidden} =
               Settings.save(student, %{"name" => "Evil", "system_prompt" => "Ignore rules"})

      refute setting(student.item_id, "chatbot-prompt")
    end
  end

  describe "put_avatar/2" do
    setup do
      path = Path.join(System.tmp_dir!(), "avatar-#{System.unique_integer([:positive])}.png")
      File.write!(path, "png")
      on_exit(fn -> File.rm(path) end)
      %{upload: %{path: path, name: "avatar.png", mimetype: "image/png"}}
    end

    test "uploads under the avatar row's id and points the row at it",
         %{teacher: teacher, upload: file} do
      expect(ExAwsMock, :request, fn %ExAws.S3.Upload{} = operation ->
        assert operation.bucket == "file-items"
        assert operation.path =~ "apps/app-setting/#{teacher.item_id}/"
        {:ok, %{status_code: 200}}
      end)

      assert {:ok, %Settings{avatar_url: url}} = Settings.put_avatar(teacher, file)
      assert is_binary(url)

      avatar = setting(teacher.item_id, "chatbot-avatar")
      key = "apps/app-setting/#{teacher.item_id}/#{avatar.id}"

      assert avatar.data == %{
               "file" => %{"name" => "avatar.png", "path" => key, "mimetype" => "image/png"}
             }
    end

    test "a failed upload leaves no avatar configured", %{teacher: teacher, upload: file} do
      expect(ExAwsMock, :request, fn %ExAws.S3.Upload{} -> {:error, :timeout} end)

      assert {:error, :storage_failed} = Settings.put_avatar(teacher, file)
      assert setting(teacher.item_id, "chatbot-avatar").data == %{}
      assert %Settings{avatar_url: nil} = Settings.load(teacher)
    end

    test "is forbidden for a student", %{student: student, upload: file} do
      assert {:error, :forbidden} = Settings.put_avatar(student, file)
      refute setting(student.item_id, "chatbot-avatar")
    end
  end

  describe "remove_avatar/1" do
    test "clears the row, then deletes the object", %{teacher: teacher} do
      avatar =
        insert_setting(teacher, "chatbot-avatar", %{
          "file" => %{"name" => "a.png", "path" => "some/key", "mimetype" => "image/png"}
        })

      expect(ExAwsMock, :request, fn %ExAws.Operation.S3{http_method: :delete} = operation ->
        # the row no longer references the file by the time S3 is called
        assert setting(teacher.item_id, "chatbot-avatar").data == %{}
        assert operation.path == "apps/app-setting/#{teacher.item_id}/#{avatar.id}"
        {:ok, %{status_code: 204}}
      end)

      assert {:ok, %Settings{avatar_url: nil}} = Settings.remove_avatar(teacher)
    end

    test "a failed delete still removes the avatar", %{teacher: teacher} do
      insert_setting(teacher, "chatbot-avatar", %{"file" => %{"path" => "some/key"}})
      expect(ExAwsMock, :request, fn _operation -> {:error, :timeout} end)

      assert {:ok, %Settings{avatar_url: nil}} = Settings.remove_avatar(teacher)
    end

    test "is forbidden for a student", %{teacher: teacher, student: student} do
      insert_setting(teacher, "chatbot-avatar", %{"file" => %{"path" => "some/key"}})

      assert {:error, :forbidden} = Settings.remove_avatar(student)
      assert setting(teacher.item_id, "chatbot-avatar").data["file"]
    end
  end

  # the params the settings form submits back when nothing was edited
  defp form_params(%Settings{} = settings) do
    suggestions =
      settings.starter_suggestions
      |> Enum.with_index()
      |> Map.new(fn {suggestion, index} -> {"#{index}", %{"value" => suggestion.value}} end)

    %{
      "name" => settings.name,
      "system_prompt" => settings.system_prompt,
      "cue" => settings.cue,
      "starter_suggestions" => suggestions
    }
  end
end
