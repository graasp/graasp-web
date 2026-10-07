defmodule Admin.Chatbot.OpenAI do
  @moduledoc """
  Streams chat completions from OpenAI for the chatbot app, using the
  `openai_ex` library (https://openai-ex.hexdocs.pm/userguide.html), with
  its own `OPENAI_API_KEY` — independent from core's `/chat-bot` route and
  from the legacy `graasp-openai` lambda.

  Runs the request in a supervised, unlinked `Task` (`Admin.TaskSupervisor`)
  and streams chunks back to the caller via plain messages, so a LiveView
  can `send(self(), ...)` results into its own `handle_info/2` and update
  assigns incrementally for a "typing" effect.
  """

  require Logger

  alias OpenaiEx.Chat
  alias OpenaiEx.ChatMessage

  @default_model "gpt-4o-mini"

  @type role :: :system | :user | :assistant
  @type message :: %{role: role(), content: String.t()}

  @doc """
  Builds the prompt: optional system message (the teacher's configured
  initial prompt), optional second system message with the Context
  Documents (`Admin.Chatbot.ContextDocument.prompt_context/1`), then the
  existing thread history, then the new user message. Mirrors the React
  app's `buildPrompt` (graasp-apps-query-client/src/utils/chatbot.ts) —
  `thread_messages` must NOT include `new_user_message`, it's appended here.
  """
  @spec build_prompt(String.t() | nil, String.t() | nil, [message()], String.t()) :: [message()]
  def build_prompt(initial_prompt, documents_context, thread_messages, new_user_message) do
    system_messages =
      for content <- [initial_prompt, documents_context], content not in [nil, ""] do
        %{role: :system, content: content}
      end

    system_messages ++ thread_messages ++ [%{role: :user, content: new_user_message}]
  end

  @doc """
  Starts streaming a chat completion for `messages` (as built by
  `build_prompt/4`). Sends messages to `pid` (defaults to the caller):

    * `{:chatbot_delta, ref, text_chunk}` — for every token chunk received
    * `{:chatbot_done, ref, {:ok, full_text}}` — once the stream completes
    * `{:chatbot_done, ref, {:error, reason}}` — on failure

  Returns a unique `ref` so the caller can tell concurrent/stale streams
  apart (e.g. ignore a stream that's no longer the active one).
  """
  @spec stream_completion([message()], pid()) :: reference()
  def stream_completion(messages, pid \\ self()) do
    ref = make_ref()

    {:ok, _task_pid} =
      Task.Supervisor.start_child(Admin.TaskSupervisor, fn -> run_stream(messages, pid, ref) end)

    ref
  end

  defp run_stream(messages, pid, ref) do
    client = OpenaiEx.new(api_key()) |> OpenaiEx.with_finch_name(Admin.Chatbot.Finch)

    chat_req =
      Chat.Completions.new(
        model: model(),
        messages: Enum.map(messages, &to_chat_message/1)
      )

    case Chat.Completions.create(client, chat_req, stream: true) do
      {:ok, chat_stream} ->
        full_text =
          chat_stream.body_stream
          |> Stream.flat_map(& &1)
          |> Enum.reduce("", fn chunk, acc ->
            Logger.debug("Admin.Chatbot.OpenAI raw chunk: #{inspect(chunk)}")

            case extract_delta(chunk) do
              delta when delta in [nil, ""] ->
                acc

              delta ->
                send(pid, {:chatbot_delta, ref, delta})
                acc <> delta
            end
          end)

        Logger.info(
          "Admin.Chatbot.OpenAI stream completed, #{byte_size(full_text)} bytes accumulated"
        )

        send(pid, {:chatbot_done, ref, {:ok, full_text}})

      {:error, reason} ->
        Logger.error("Admin.Chatbot.OpenAI stream request failed: #{inspect(reason)}")
        send(pid, {:chatbot_done, ref, {:error, reason}})
    end
  rescue
    error ->
      Logger.error(
        "Admin.Chatbot.OpenAI stream crashed: #{Exception.format(:error, error, __STACKTRACE__)}"
      )

      send(pid, {:chatbot_done, ref, {:error, error}})
  end

  # openai_ex's SSE parser (OpenaiEx.HttpSse) wraps every event as
  # `%{data: decoded_json}` (or `%{event: ..., data: decoded_json}`) — the
  # OpenAI chat-completion payload itself (with the "choices"/"delta" keys)
  # lives under `:data`, not at the top level.
  defp extract_delta(%{data: data}) when is_map(data), do: extract_content(data)

  defp extract_delta(chunk) do
    Logger.warning("Admin.Chatbot.OpenAI unrecognized chunk shape: #{inspect(chunk)}")
    nil
  end

  defp extract_content(%{"choices" => [%{"delta" => %{"content" => content}} | _]})
       when is_binary(content),
       do: content

  defp extract_content(_data), do: nil

  defp to_chat_message(%{role: :system, content: content}), do: ChatMessage.system(content)
  defp to_chat_message(%{role: :user, content: content}), do: ChatMessage.user(content)
  defp to_chat_message(%{role: :assistant, content: content}), do: ChatMessage.assistant(content)

  defp api_key, do: Application.fetch_env!(:admin, :openai_api_key)
  defp model, do: Application.get_env(:admin, :openai_model, @default_model)
end
