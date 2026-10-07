defmodule Admin.Chatbot.ContextDocumentTest do
  use Admin.DataCase

  # the storage-failure tests log the (expected) S3 errors
  @moduletag :capture_log

  import Mox
  import Admin.AccountsFixtures
  import Admin.ItemsFixtures

  alias Admin.Apps.AppSetting
  alias Admin.Chatbot.ContextDocument
  alias Admin.Chatbot.Scope

  @fixtures Path.expand("../../fixtures/chatbot", __DIR__)

  setup :verify_on_exit!

  setup do
    item = item_fixture(user_scope_fixture())
    teacher = %Scope{item_id: item.id, account_id: item.creator_id, teacher?: true}
    student = %{teacher | teacher?: false}

    upload = %{path: Path.join(@fixtures, "two_pages.pdf"), name: "lesson.pdf", size: 1307}
    %{teacher: teacher, student: student, upload: upload}
  end

  defp rows(item_id) do
    Repo.all(from s in AppSetting, where: s.item_id == ^item_id and s.name == "chatbot-context")
  end

  defp insert_document(scope, data, created_at \\ nil) do
    Repo.insert!(%AppSetting{
      item_id: scope.item_id,
      creator_id: scope.account_id,
      name: "chatbot-context",
      data: data,
      created_at: created_at
    })
  end

  defp document_data(attrs) do
    Map.merge(
      %{
        "file" => %{"name" => "doc.pdf", "path" => "some/key", "mimetype" => "application/pdf"},
        "text" => "Some text",
        "tokens" => 3,
        "pages" => 1,
        "size" => 100
      },
      attrs
    )
  end

  defp expect_upload(item_id) do
    expect(ExAwsMock, :request, fn %ExAws.S3.Upload{} = operation ->
      assert operation.path =~ "apps/app-setting/#{item_id}/"
      {:ok, %{status_code: 200}}
    end)
  end

  describe "add/2" do
    test "extracts, uploads under the row's id and stores the text next to the file",
         %{teacher: teacher, upload: upload} do
      expect_upload(teacher.item_id)

      assert {:ok, %ContextDocument{name: "lesson.pdf", pages: 2} = document} =
               ContextDocument.add(teacher, upload)

      assert document.text =~ "Photosynthesis"
      assert document.tokens == ContextDocument.estimate_tokens(document.text)

      [row] = rows(teacher.item_id)
      assert row.id == document.id

      assert row.data == %{
               "file" => %{
                 "name" => "lesson.pdf",
                 "path" => "apps/app-setting/#{teacher.item_id}/#{row.id}",
                 "mimetype" => "application/pdf"
               },
               "text" => document.text,
               "tokens" => document.tokens,
               "pages" => 2,
               "size" => 1307
             }
    end

    test "rejects a document over the remaining token budget", %{
      teacher: teacher,
      upload: upload
    } do
      insert_document(teacher, document_data(%{"tokens" => ContextDocument.max_tokens() - 10}))

      assert {:error, {:over_budget, tokens, 10}} = ContextDocument.add(teacher, upload)
      assert tokens > 10
      assert length(rows(teacher.item_id)) == 1
    end

    test "rejects a document past the maximum count", %{teacher: teacher, upload: upload} do
      for _ <- 1..ContextDocument.max_documents(),
          do: insert_document(teacher, document_data(%{}))

      assert {:error, :too_many_documents} = ContextDocument.add(teacher, upload)
    end

    test "rejects a PDF without text, without uploading it", %{teacher: teacher} do
      upload = %{path: Path.join(@fixtures, "no_text.pdf"), name: "scan.pdf", size: 543}

      assert {:error, :no_text} = ContextDocument.add(teacher, upload)
      assert rows(teacher.item_id) == []
    end

    test "a failed upload stores nothing", %{teacher: teacher, upload: upload} do
      expect(ExAwsMock, :request, fn %ExAws.S3.Upload{} -> {:error, :timeout} end)

      assert {:error, :storage_failed} = ContextDocument.add(teacher, upload)
      assert rows(teacher.item_id) == []
    end

    test "is forbidden for a student", %{student: student, upload: upload} do
      assert {:error, :forbidden} = ContextDocument.add(student, upload)
      assert rows(student.item_id) == []
    end
  end

  describe "list/1" do
    test "lists documents oldest first, a row without text as unavailable", %{teacher: teacher} do
      # what a copy by core without the data-merge fix leaves behind
      insert_document(
        teacher,
        %{"file" => %{"name" => "b.pdf", "path" => "p"}},
        ~U[2026-01-02 00:00:00Z]
      )

      insert_document(
        teacher,
        document_data(%{"file" => %{"name" => "a.pdf"}}),
        ~U[2026-01-01 00:00:00Z]
      )

      assert [
               %ContextDocument{name: "a.pdf", tokens: 3} = available,
               %ContextDocument{name: "b.pdf", tokens: 0, text: nil} = unavailable
             ] = ContextDocument.list(teacher)

      assert ContextDocument.available?(available)
      refute ContextDocument.available?(unavailable)
    end
  end

  describe "remove/2" do
    test "deletes the row, then the object", %{teacher: teacher} do
      row = insert_document(teacher, document_data(%{}))

      expect(ExAwsMock, :request, fn %ExAws.Operation.S3{http_method: :delete} = operation ->
        assert rows(teacher.item_id) == []
        assert operation.path == "apps/app-setting/#{teacher.item_id}/#{row.id}"
        {:ok, %{status_code: 204}}
      end)

      assert :ok = ContextDocument.remove(teacher, row.id)
    end

    test "a failed delete still removes the document", %{teacher: teacher} do
      row = insert_document(teacher, document_data(%{}))
      expect(ExAwsMock, :request, fn _operation -> {:error, :timeout} end)

      assert :ok = ContextDocument.remove(teacher, row.id)
      assert rows(teacher.item_id) == []
    end

    test "only removes the item's own documents", %{teacher: teacher} do
      other_item = item_fixture(user_scope_fixture())
      other_scope = %{teacher | item_id: other_item.id}
      row = insert_document(other_scope, document_data(%{}))

      assert {:error, :not_found} = ContextDocument.remove(teacher, row.id)
      assert {:error, :not_found} = ContextDocument.remove(teacher, "not-a-uuid")
      assert length(rows(other_item.id)) == 1
    end

    test "is forbidden for a student", %{teacher: teacher, student: student} do
      row = insert_document(teacher, document_data(%{}))

      assert {:error, :forbidden} = ContextDocument.remove(student, row.id)
      assert length(rows(teacher.item_id)) == 1
    end
  end

  describe "prompt_context/1" do
    test "is nil without available documents" do
      assert ContextDocument.prompt_context([]) == nil

      assert ContextDocument.prompt_context([%ContextDocument{id: "1", name: "a.pdf"}]) == nil
    end

    test "wraps each available document with its name" do
      context =
        ContextDocument.prompt_context([
          %ContextDocument{id: "1", name: ~s(my "notes".pdf), text: "First text"},
          %ContextDocument{id: "2", name: "gone.pdf"},
          %ContextDocument{id: "3", name: "b.pdf", text: "Second text"}
        ])

      assert context =~ ~s(<document name="my 'notes'.pdf">\nFirst text\n</document>)
      assert context =~ ~s(<document name="b.pdf">\nSecond text\n</document>)
      refute context =~ "gone.pdf"
    end
  end

  describe "check_limits/2" do
    test "counts unavailable documents towards the count, not the budget" do
      documents = for i <- 1..4, do: %ContextDocument{id: "#{i}", name: "d.pdf"}

      assert :ok = ContextDocument.check_limits(documents, ContextDocument.max_tokens())

      assert {:error, :too_many_documents} =
               ContextDocument.check_limits(
                 [%ContextDocument{id: "5", name: "d.pdf"} | documents],
                 1
               )
    end
  end
end
