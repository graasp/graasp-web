defmodule AdminWeb.Dev.ChatbotMockController do
  @moduledoc """
  Dev-only page that plays the role of the Graasp parent frame for the
  chatbot app (`/apps/chatbot`), so it can be exercised locally without a
  running core instance. Mints a valid app JWT itself via
  `Admin.Apps.Token.sign_dev_token/1`, since there's no core around to
  issue one.

  Visit `/dev/chatbot-mock`. Default is `admin` permission from the
  `builder` context, i.e. the teacher view (the LiveView only shows it when
  both are true, mirroring the React app's `App.tsx`/`BuilderView.tsx`).
  Override with `?permission=read` and/or `?context=player` to see the
  student view.
  """
  use AdminWeb, :controller

  alias Admin.Apps.Token

  def index(conn, params) do
    item_id = Map.get(params, "itemId", Ecto.UUID.generate())
    account_id = Map.get(params, "accountId", Ecto.UUID.generate())
    permission = Map.get(params, "permission", "admin")
    app_context = Map.get(params, "context", "builder")

    {:ok, token} =
      Token.sign_dev_token(%{
        "accountId" => account_id,
        "itemId" => item_id,
        "origin" => AdminWeb.Endpoint.url(),
        "key" => Application.fetch_env!(:admin, :graasp_app_key)
      })

    context = %{
      itemId: item_id,
      accountId: account_id,
      permission: permission,
      apiHost: "http://localhost:3111",
      lang: "en",
      context: app_context
    }

    conn
    |> put_root_layout(false)
    |> html(render_page(item_id, token, context))
  end

  defp render_page(item_id, token, context) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Chatbot mock parent</title>
      </head>
      <body style="margin:0">
        <p style="font: 12px monospace; padding: 8px;">
          Mock Graasp parent &mdash; itemId=#{item_id}
        </p>
        <iframe
          id="chatbot-frame"
          src="/apps/chatbot?itemId=#{item_id}"
          style="width:100%;height:200px;border:1px solid #ccc"
        ></iframe>
        <script>
          const itemId = #{Jason.encode!(item_id)};
          const token = #{Jason.encode!(token)};
          const context = #{Jason.encode!(context)};
          const keys = {
            GET_CONTEXT: `GET_CONTEXT_${itemId}`,
            GET_CONTEXT_SUCCESS: `GET_CONTEXT_SUCCESS_${itemId}`,
            GET_AUTH_TOKEN: `GET_AUTH_TOKEN_${itemId}`,
            GET_AUTH_TOKEN_SUCCESS: `GET_AUTH_TOKEN_SUCCESS_${itemId}`,
            POST_AUTO_RESIZE: `POST_AUTO_RESIZE_${itemId}`,
          };

          // acts as the parent side of the handshake implemented by
          // assets/js/hooks/graasp_context.js
          window.addEventListener("message", (event) => {
            let parsed;
            try {
              parsed = JSON.parse(event.data);
            } catch (e) {
              return;
            }
            if (!parsed || parsed.type !== keys.GET_CONTEXT) return;

            const channel = new MessageChannel();
            channel.port1.onmessage = (portEvent) => {
              let msg;
              try {
                msg = JSON.parse(portEvent.data);
              } catch (e) {
                return;
              }
              if (msg && msg.type === keys.GET_AUTH_TOKEN) {
                channel.port1.postMessage(
                  JSON.stringify({
                    type: keys.GET_AUTH_TOKEN_SUCCESS,
                    payload: { token },
                  }),
                );
              } else if (msg && msg.type === keys.POST_AUTO_RESIZE) {
                // real Graasp resizes the iframe element itself on this
                // message; mimic that here so auto-resize is testable locally
                document.getElementById("chatbot-frame").style.height =
                  `${msg.payload}px`;
              }
            };

            const frameWindow =
              document.getElementById("chatbot-frame").contentWindow;
            frameWindow.postMessage(
              JSON.stringify({
                type: keys.GET_CONTEXT_SUCCESS,
                payload: context,
              }),
              "*",
              [channel.port2],
            );
          });
        </script>
      </body>
    </html>
    """
  end
end
