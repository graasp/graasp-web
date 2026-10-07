defmodule Admin.Chatbot.OpenAITest do
  use ExUnit.Case, async: true

  alias Admin.Chatbot.OpenAI

  describe "build_prompt/4" do
    test "puts the system prompt, then the documents, then the thread" do
      history = [%{role: :assistant, content: "Hi!"}]

      assert OpenAI.build_prompt("Be concise.", "<document>…</document>", history, "Why?") == [
               %{role: :system, content: "Be concise."},
               %{role: :system, content: "<document>…</document>"},
               %{role: :assistant, content: "Hi!"},
               %{role: :user, content: "Why?"}
             ]
    end

    test "skips missing system messages" do
      assert OpenAI.build_prompt(nil, nil, [], "Why?") == [%{role: :user, content: "Why?"}]
    end
  end
end
