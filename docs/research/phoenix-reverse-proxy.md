# Research: reverse-proxying core from Phoenix

Resolves graasp/graasp-web#315 (part of the map #312). Question: what are the facts for proxying core's HTTP and websocket traffic from admin (Phoenix) to core (Node/Fastify), without buffering, while keeping core's API contract intact?

Researched 2026-11-13 against the versions in admin's `mix.lock`. The source for each claim was read in `deps/` at that version, or on hexdocs/GitHub for packages admin doesn't depend on yet:

| Package | Locked | Notes |
|---|---|---|
| bandit | 1.10.4 | HTTP server (`config/config.exs`: `adapter: Bandit.PhoenixAdapter`) |
| plug | 1.20.2 | |
| phoenix | 1.8.5 | |
| req | 0.6.2 | `mix.exs` says `~> 0.5`, so the lock has already moved to 0.6 |
| finch | 0.23.0 | |
| mint | 1.9.0 | |
| websock / websock_adapter | 0.5.3 / 0.5.9 | |
| thousand_island | 1.4.3 | |
| mint_web_socket | **not a dependency** | latest 1.0.6 on hex |
| reverse_proxy_plug | **not a dependency** | latest 3.0.5 on hex |

## TL;DR

1. **Write the proxy by hand. Use `Finch.stream_while/5` directly, or Req's `:finch_request` escape hatch, rather than Req's normal pipeline or `reverse_proxy_plug`.** Only `Finch.stream_while/5` with a `{:stream, req_body_fun}` request body (Finch ≥ 0.22, HTTP/1 pools only) can carry the `Plug.Conn` through both the request-body reads and the response chunks in one accumulator. Bandit requires both to happen in the conn's owner process. It also needs the *final* conn back, or it tries to drain a body that has already been read.
2. **The proxy must run in `AdminWeb.Endpoint` before `Plug.Parsers`**, and also before `Plug.Head`, `Plug.MethodOverride` and `Plug.Session`. Otherwise multipart and JSON bodies are consumed, HEAD becomes GET, and the router is never reached unparsed.
3. **`reverse_proxy_plug` 3.0.5 is not suitable:** it reads the whole request body into one binary (fatal for core's 1 GB uploads), drops `content-length` on streamed responses, and its Req adapter uses `into: :self` (spawned process, no backpressure, `receive` with no timeout). It does no websockets. The companion `reverse_proxy_plug_websocket` uses gun or WebSockex and has about 4 GitHub stars.
4. **Websockets:** use `WebSockAdapter.upgrade/4` with a small `WebSock` handler that relays frames to a `Mint.WebSocket` (new dependency) client connection. Bandit runs the plug and the WebSock handler in the same process, so a Mint connection opened in the plug still delivers its messages to the handler. Bandit cannot upgrade over HTTP/2, so clients use HTTP/1.1 for websockets.
5. **Client IP:** core records `action.geolocation` from the **leftmost** `X-Forwarded-For` entry, falling back to the socket address. The proxy must append the client IP to `X-Forwarded-For`, or every action recorded by core is geolocated to admin.
6. **Telemetry:** Phoenix's router telemetry never fires for proxied requests. Wrap each proxied call in `:telemetry.span([:admin, :proxy, :request], …)` with a low-cardinality route label, and use Bandit's `[:bandit, :request, :stop]` for full duration and byte counts. `Plug.Telemetry`'s stop event fires at `send_chunked`, so it measures time to first byte, not the whole response.

---

## 1. Where the proxy sits in admin

`lib/admin_web/endpoint.ex` currently runs, in order: `Plug.Static` → (dev reloaders) → `RequestLogger` → `Plug.RequestId` → `Plug.Telemetry` → **`Plug.Parsers`** (`:urlencoded, :multipart, :json`, `pass: ["*/*"]`) → `Sentry.PlugContext` → `Plug.MethodOverride` → **`Plug.Head`** → `Plug.Session` → `AdminWeb.Router`.

- `Plug.Parsers` reads and consumes the body for every matching content type. Multipart goes to temp files, while JSON and urlencoded are read into memory (default 8 MB limit). "Some plugs like `Plug.Parsers` may read the body, so the body may be unavailable after being accessed" (`Plug.Conn.read_body/2` docs). Core's traffic is exactly JSON and multipart, so **a proxy in the router would see no body.** `body_reader` can tee the body, but that buffers it. (deps/plug/lib/plug/parsers.ex, plug/conn.ex)
- `Plug.Head` rewrites `HEAD` to `GET`. `Plug.MethodOverride` rewrites `POST` + `_method`. `Plug.Session` would add admin's own cookie handling. None of these should apply to core's contract.
- Recommendation: add a plug such as `AdminWeb.CoreProxy` **right after `Plug.Telemetry`** (so endpoint telemetry and the request id still apply). It decides per path: either proxy and halt, or pass through to the rest of the endpoint for ported routes. As routes are ported, its "proxied" table shrinks. Phoenix `socket` declarations (`/live`) are dispatched before plugs, so they don't conflict with core's `/api/ws`, `/api/items/pages/:id/ws` and `/ws/read` (core inventory README).

## 2. Request body streaming (multipart uploads)

Facts:

- Core accepts multipart uploads up to `DEFAULT_MAX_FILE_SIZE = 1 GB` (`core/src/services/file/utils/constants.ts`, `itemFile.controller.ts`). Buffering is not an option.
- `Plug.Conn.read_body/2` reads in pieces: `:length` (default 8 MB per call), `:read_length` (1 MB per socket read) and `:read_timeout` (15 s per socket read). It returns `{:more, data, conn}` or `{:ok, data, conn}`, and it decodes both chunked and identity transfer-encoding (plug/conn.ex).
- **Bandit enforces process ownership.** `read_req_body`, `send_resp`, `send_chunked`, `chunk` and `inform` all call `validate_calling_process!`, which raises `"Adapter functions must be called by stream owner"` (deps/bandit/lib/bandit/adapter.ex:292).
- **Bandit needs the final conn.** After the plug returns, `Bandit.HTTP1.Socket.ensure_completed/1` reads any body the *returned* conn's adapter state still considers unread (http1/socket.ex:454). If the body was read through a conn copy that is then discarded, Bandit blocks re-reading a drained socket until the read timeout, then errors. **The conn returned by each `read_body` call must be threaded through to the end.**
- Req's adapter (`Req.Finch.run/1`) turns any non-binary body into `{:stream, enumerable}` (deps/req/lib/req/finch.ex:32-42). An `Enumerable` over `read_body` cannot hand its updated conn back to the caller, which hits the previous point.
- **Finch ≥ 0.22 supports `{:stream, req_body_fun}`** where `req_body_fun.(acc)` returns `{:data, chunk, acc} | {:done, acc} | {:halt, acc}` and *the same `acc` then flows into the response callback*. This works "only with `Finch.stream_while/5` on HTTP/1 pools" (deps/finch/lib/finch.ex:279-282, 610-616, 712-721; CHANGELOG 0.22.0 #357 #360; on HTTP/2 `Finch.HTTP2.Pool` raises "not yet supported"). With the conn as `acc`, it is threaded naturally.
- On HTTP/1, Finch's `stream`/`stream_while` run in the **caller** process (deps/finch/lib/finch/http1/conn.ex). `Finch.async_request/3`, which Req's `into: :self` uses, `spawn_link`s a separate process that would evaluate the body stream outside the owner (http1/pool.ex:99-121).
- Finch's HTTP/1 path sends the **entire request body before reading the response** (http1/conn.ex:108-150). An early upstream rejection (401, 413) is only seen after the upload finishes. That matches what core sees behind any buffering proxy, so no contract change.
- **Strip the inbound `transfer-encoding` header and forward `content-length` when present.** Mint only does chunked encoding itself if neither header is set. If you pass `content-length`, "making sure the content length is correct ... is up to you", and if you pass `transfer-encoding: chunked` you must encode the chunks yourself (deps/mint/lib/mint/http1.ex:348-366). `read_body` hands over already-decoded bytes, so forwarding the client's `transfer-encoding: chunked` would corrupt the request.

## 3. Response streaming (downloads, redirects)

Facts:

- Core does stream bytes: export/download sets `Content-Disposition` and streams the file (`core/src/services/item/plugins/importExport/importExport.controller.ts:137`). `GET /items/:id/download` and the thumbnail routes return the **signed S3 URL in the body** (`itemFile.controller.ts:182`, `itemThumbnail.controller.ts:89-97`), not a 302. Real redirects exist: the magic-link controller replies `303 See Other` (`magicLink.controller.ts:100,124`).
- **Req's default pipeline is wrong for a proxy, and every default has to be turned off:**
  - `redirect: true` follows 301/302/303/307/308, so it would follow core's 303 instead of relaying it. It even cancels an async body to re-request (req/steps.ex `redirect/1`).
  - `retry: :safe_transient` re-sends GET/HEAD on 408/429/5xx and on transport errors, with 1 s/2 s/4 s backoff (steps.ex `retry/1`).
  - `decode_body` JSON-decodes responses.
  - `put_user_agent` adds `req/…` when the header is absent.
  - Since 0.6.1 `compressed` is off by default (CHANGELOG), which is what a proxy wants.
  - `Req.Request.new/1` builds a request with no steps at all. Alternatively, pass `retry: false, redirect: false, decode_body: false` (or `raw: true`).
- Req's streaming modes (finch.ex):
  - `into: fun` → `Finch.stream_while/5` in the caller. The fun receives `{:data, chunk}` with `{req, resp}` as the accumulator, so status and headers are already on `resp` at the first chunk. It is **never called for an empty body** (204, 304, HEAD), so the plug must `send_resp` afterwards if nothing was sent.
  - `into: :self` → `Finch.async_request/3`. It is documented as experimental and "a firehose": messages arrive "as soon as they arrive", with no backpressure (req/response_async.ex). The initial status/headers `receive` has no `after` clause (finch.ex:258-274).
  - `into: collectable` buffers non-200 bodies into a binary.
- **Backpressure comes free with `stream_while` on HTTP/1:** Finch calls `Mint.HTTP.recv` only after the callback returns, and Bandit's `chunk/2` writes to the socket synchronously. A slow client therefore slows the upstream read. `chunk/2` returns `{:error, reason}` instead of raising when the client is gone (bandit/adapter.ex:171-200), so return `{:halt, acc}` and Finch closes the upstream HTTP/1 connection (finch.ex `stream_while` docs). Finch warns that HTTP/2 streaming has **no** backpressure (finch.ex:743-750), so keep the core pool on HTTP/1. That is Req/Finch's default `protocols: [:http1]` (req/finch.ex:432-434).
- Bandit response behaviour that matters:
  - `send_chunked` with a `content-length` response header writes raw bytes with **no chunk framing** (`write_state: :chunk_streaming`). Without one it adds `transfer-encoding: chunked` (bandit/http1/socket.ex:349-372). So forwarding core's `content-length` keeps download sizes and progress bars intact. Always **drop core's `transfer-encoding`** and other hop-by-hop headers, or the response gets two framing headers.
  - **Bandit compresses responses by default** (`http_options: [compress: true]`, deflate for streamed responses) unless the response already has `content-encoding`, a strong `etag`, or `cache-control: no-transform` (bandit/compression.ex:33-49). For a proxied response carrying core's `content-length`, compression would make the length wrong. Either delete `content-length` when Bandit will compress, add `cache-control: no-transform`, or (simplest) set `http_options: [compress: false]` for the endpoint and let the edge proxy compress. Admin's `config/runtime.exs` sets no `http_options` today.
  - `inform/3` (1xx) exists but no core route needs it.

## 4. Headers: Host, cookies, Set-Cookie, X-Forwarded-*, client IP

- **Hop-by-hop headers to drop in both directions:** `connection`, `keep-alive`, `te`, `trailer`, `transfer-encoding`, `upgrade`, `proxy-authenticate`, `proxy-authorization`, plus any header named in `Connection` (RFC 9110 §7.6.1). This is the same list as `reverse_proxy_plug`'s `remove_hop_by_hop_headers/1`.
- **Host:** Mint only sets `host` if none is given (`Headers.put_new("Host", …)`, mint/http1.ex:1098). Forwarding the client's `host` therefore preserves it. Core uses the request host to build URLs, so keep it and also send `x-forwarded-host`.
- **Cookies:** forward `cookie` verbatim. Core's session is `@fastify/secure-session` with `domain: COOKIE_DOMAIN, path: "/"`, renewed on every request (`core/src/services/auth/plugins/passport/plugin.ts:38-52`). So many responses carry `Set-Cookie`, and some carry several.
  - Req keeps response headers as `%{name => [values]}`. Emit **one `set-cookie` header per value**. `Plug.Conn.put_resp_header/3` *replaces*, so prepend the tuples to `conn.resp_headers` (or use `merge_resp_headers` per value carefully). Never join `set-cookie` values with commas. (`reverse_proxy_plug`'s Req adapter special-cases this the same way.)
  - Admin's own `_admin_key` cookie is also sent to core and ignored there. Running the proxy before `Plug.Session` keeps admin from writing its own session cookie on proxied responses.
- **Client IP:** core computes `forwarded(request.raw).pop()` in `ActionService` (`core/src/services/action/action.service.ts:69-73`). The npm `forwarded` package returns `[socketAddr, …XFF entries right-to-left]` (jshttp/forwarded `index.js`), so `.pop()` is the **leftmost XFF entry, or the socket address if no XFF**. Core is a `fastify({...})` instance without `trustProxy` (`core/src/fastify.ts:15`). The proxy must send `x-forwarded-for: <existing>, <conn.remote_ip>`, or set it to `conn.remote_ip` when absent.
  - Upstream of admin, `Plug.RewriteOn, [:x_forwarded_for]` sets `conn.remote_ip` from the **first** XFF entry. Like core, it is spoofable unless the edge strips client-supplied XFF (deps/plug/lib/plug/rewrite_on.ex:133-141 and moduledoc security note).
- Also forward `x-forwarded-proto`/`x-forwarded-port` and `x-request-id` (already set by `Plug.RequestId`) for log correlation. Keep `origin`: core derives the action `view` from `headers.origin` (action.service.ts:60-62).
- To match core's own behaviour, don't add `via` or rewrite `location`: core's frontends expect core's exact headers.

## 5. Library vs hand-written plug

**`reverse_proxy_plug` 3.0.5** ([docs](https://reverse-proxy-plug.hexdocs.pm/readme.html), source `tallarium/reverse_proxy_plug` `lib/reverse_proxy_plug.ex`):

- Its clients are HTTPoison (the default, which raises if absent), Tesla, Finch and Req. `response_mode: :stream` is the default, and `:buffer` is the alternative. It returns 502 on errors and 504 on timeouts, and has `error_callback`, `status_callbacks` and `preserve_host_header`.
- `read_body/2` **concatenates the whole request body into one binary** (`Enum.reduce` over `Plug.Conn.read_body`) before sending. Its docs also recommend moving `Plug.Parsers` and caching the body in `assigns[:raw_body]`.
- In stream mode it **removes `content-length`** from responses (`send_stream_response_headers/3`).
- The Req adapter uses `Req.request(into: :self)` without `redirect: false`, so Req would follow core's 303 unless you pass `client_options: [redirect: false]`. Its `body_stream` `receive`s with no timeout and no `{:error, _}` clause.
- It sets `x-forwarded-for` but no `x-forwarded-proto`/`host`. There are no websockets; the docs point to `reverse_proxy_plug_websocket` (0.2.0, gun or WebSockex upstream, about 4 stars on GitHub).

**Verdict:** a hand-written plug is about 150 lines (sketch below). It gets true request streaming, correct `content-length`/`set-cookie` handling, no redirects or retries, and route-labelled telemetry. The library would need forking to fix the body buffering anyway.

### Sketch (uncompiled, for shape only)

```elixir
# In AdminWeb.Endpoint, right after Plug.Telemetry:
#   plug AdminWeb.CoreProxy, finch: Admin.CoreFinch, upstream: "http://core:3000"
# Admin.Application children: {Finch, name: Admin.CoreFinch, pools: %{default: [size: 50, protocols: [:http1]]}}

def call(conn, opts) do
  case route_label(conn) do              # nil = ported, let Phoenix handle it
    nil -> conn
    label when websocket_upgrade?(conn) -> AdminWeb.CoreProxy.WS.upgrade(conn, label, opts) |> halt()
    label -> proxy_http(conn, label, opts) |> halt()
  end
end

defp proxy_http(conn, label, opts) do
  body = if body?(conn), do: {:stream, &read_chunk/1}, else: nil
  req  = Finch.build(conn.method, upstream_url(conn, opts), upstream_headers(conn), body)
  acc  = %{conn: conn, body_done?: false, status: nil, headers: [], sent?: false}

  :telemetry.span([:admin, :proxy, :request], %{route: label, method: conn.method}, fn ->
    result = Finch.stream_while(req, opts[:finch], acc, &on_response/2,
               receive_timeout: 60_000, request_timeout: :infinity)
    conn = finish(result)
    {conn, %{route: label, method: conn.method, status: conn.status}}
  end)
end

# request body: conn threaded through acc (Bandit owner + ensure_completed)
defp read_chunk(%{body_done?: true} = acc), do: {:done, acc}
defp read_chunk(%{conn: conn} = acc) do
  case Plug.Conn.read_body(conn, length: 1_000_000, read_timeout: 30_000) do
    {:more, data, conn} -> {:data, data, %{acc | conn: conn}}
    {:ok, data, conn}   -> {:data, data, %{acc | conn: conn, body_done?: true}}
    {:error, _}         -> {:halt, acc}
  end
end

defp on_response({:status, s}, acc), do: {:cont, %{acc | status: s}}
defp on_response({:headers, h}, %{sent?: false} = acc), do: {:cont, %{acc | headers: h}}
defp on_response({:data, d}, %{sent?: false} = acc),
  do: acc |> start_chunked() |> send_chunk(d)
defp on_response({:data, d}, acc), do: send_chunk(acc, d)
defp on_response(_trailers_or_late_headers, acc), do: {:cont, acc}

defp start_chunked(%{conn: conn, status: s, headers: h} = acc) do
  conn = %{conn | resp_headers: response_headers(h)}   # hop-by-hop stripped, set-cookie kept per value
  %{acc | conn: Plug.Conn.send_chunked(conn, s), sent?: true}
end

defp send_chunk(acc, d) do
  case Plug.Conn.chunk(acc.conn, d) do
    {:ok, conn} -> {:cont, %{acc | conn: conn}}
    {:error, _closed} -> {:halt, acc}                  # client gone → Finch closes upstream
  end
end

# finish/1: {:ok, %{sent?: false}} → send_resp(status, "") with headers (204/304/HEAD/empty);
# {:error, %Finch.TransportError{reason: :timeout}, %{sent?: false}} → 504;
# other errors before sending → 502; errors after sending → return acc.conn (connection is cut).
```

The same flow is reachable through Req with `finch_request: fn req, finch_req, name, opts -> … end` (a 4-arity function; req/steps.ex `run_finch/1` docs). That only helps if Req steps such as `put_base_url` or `auth` are wanted, and for a proxy they aren't.

## 6. Websockets

Core endpoints: `/api/ws` (realtime, Redis-backed), `/api/items/pages/:id/ws` and `/ws/read` (collaborative pages) (core-inventory README). They use `@fastify/websocket` and authenticate with the session cookie on the upgrade request.

Facts:

- `WebSockAdapter.upgrade(conn, handler, state, opts)` validates the request (`early_validate_upgrade: true`) and calls `Plug.Conn.upgrade_adapter(conn, :websocket, …)`. The handshake itself happens **after the plug returns**. Options include `timeout` (idle, default 60 s), `compress` (default false), `max_frame_size`, `max_heap_size` and `fullsweep_after` (deps/websock_adapter/lib/websock_adapter.ex).
- Bandit's handshake appends `conn.resp_headers` to the 101 response (bandit/websocket/handshake.ex `send_handshake/2`). That is how to relay a `sec-websocket-protocol` chosen by core, or a `set-cookie` it sent. WebSockAdapter has no subprotocol option.
- **Same process:** Bandit's HTTP/1 handler returns `{:switch, Bandit.WebSocket.Handler, …}` via `DelegatingHandler`, so the WebSock handler runs in the process that ran the plug (bandit/http1/handler.ex:16,51-53). A Mint socket opened during the plug, in `:active` mode, keeps delivering messages to that process, and they arrive in `handle_info/2`.
- **No websockets over HTTP/2 in Bandit:** `supported_upgrade?/2` is `false` for HTTP/2 streams (bandit/http2/stream.ex:574). Browsers fall back to HTTP/1.1 for websockets automatically.
- Bandit answers client pings itself and then calls the optional `handle_control/2` (bandit/websocket/connection.ex:128-147).
- **Upstream client: `Mint.WebSocket` 1.0.6** ([docs](https://mint-web-socket.hexdocs.pm/Mint.WebSocket.html)). It is process-less like Mint, and uses the same Mint version admin already has.
  - Flow: `Mint.HTTP.connect` → `Mint.WebSocket.upgrade(:ws, conn, path, headers, opts)` → on the `:status`/`:headers` responses → `Mint.WebSocket.new(conn, ref, status, headers)`. Then use `stream/2` + `decode/2` for incoming data and `encode/2` + `stream_request_body/3` for outgoing data.
  - "Responding to pings with pongs must be implemented by the user", and it is "not fully spec-conformant on its own".
  - It supports HTTP/2 extended CONNECT (RFC 8441) but HTTP/1 is the default.
  - Alternatives: `gun` (Erlang, its own process) and WebSockex (process-based), both of which `reverse_proxy_plug_websocket` uses. Mint.WebSocket fits better because it lives inside the WebSock process with no extra process and no extra mailbox hop.
- Recommended shape:
  1. In the plug, open Mint plus the upgrade to core **before** calling `WebSockAdapter.upgrade`. Forward `cookie`, `origin`, `sec-websocket-protocol`, `user-agent` and `x-forwarded-*`, but not `sec-websocket-key`/`-version`/`-extensions`, which Mint.WebSocket generates itself. Wait (bounded) for core's 101. Then:
     - if core refuses (401/403/404), relay that status as a normal HTTP response, which preserves the contract;
     - if core accepts, copy its `sec-websocket-protocol`/`set-cookie` into `resp_headers` and upgrade, passing the Mint conn and websocket as WebSock state.
  2. Map callbacks to frames:
     - `handle_in({data, opcode: :text | :binary})` → encode and send upstream;
     - `handle_info(mint_msg)` → `Mint.WebSocket.stream` + `decode`, then `{:push, frames, state}` to the client, answer upstream `{:ping, d}` with `{:pong, d}`, and turn an upstream `{:close, code, reason}` into `{:stop, :normal, {code, reason}, state}`;
     - `terminate/2` → send a close upstream and `Mint.HTTP.close`.
  3. Backpressure is weaker than for HTTP: Mint `:active` mode pushes every upstream packet into the mailbox while `{:push, …}` writes to the client synchronously. Core's realtime traffic is small notifications, so cap the risk with `max_heap_size` in the upgrade opts. If needed, `Mint.HTTP.set_mode(conn, :passive)` + `recv` gives pull-based reads.
  4. Phoenix's `check_origin` does not apply to a hand-rolled upgrade. Origin checks remain core's job, which is fine as long as `origin` is forwarded.

## 7. Timeouts

| Layer | Setting | Default | Source |
|---|---|---|---|
| Client → admin, idle keepalive / header read | Thousand Island `read_timeout` (`thousand_island_options`) | 60 s | thousand_island.ex:142 |
| Client → admin, request body per socket read | `Plug.Conn.read_body :read_timeout` | 15 s | plug/conn.ex |
| Admin → core, pool checkout | Finch/Req `pool_timeout` | 5 s | finch.ex:857; req/steps.ex |
| Admin → core, between chunks | Finch/Req `receive_timeout` | 15 s | finch.ex:860 |
| Admin → core, whole response (HTTP/1 only, best effort) | Finch `request_timeout` | `:infinity` | finch.ex:863-866 (Req does **not** pass this one through, only `receive_timeout`/`pool_timeout`: req/finch.ex:49-50) |
| Admin → core, TCP connect | Finch `conn_opts: [transport_opts: [timeout: …]]` / Req `connect_options: [timeout:]` | 30 s (Req) | req/steps.ex |
| Websocket idle | `WebSockAdapter.upgrade` `timeout` | 60 s | websock_adapter.ex |

Notes:

- The per-chunk `receive_timeout` of 15 s applies **while core is still processing**, before the first byte. Slow core endpoints (exports, imports, AI/chatbot calls) need a per-route override, for example a 120 s `receive_timeout`, chosen from the route table.
- Map a `Finch.TransportError{reason: :timeout}` before any byte was sent to **504**, and other transport errors to **502**. This matches `reverse_proxy_plug`'s defaults. After the response has started, the only option is to abort the connection.
- The pool size bounds concurrency to core. Uploads and long downloads each hold an HTTP/1 connection for their whole duration. Size the pool from proxy traffic, and use a separate tagged pool (`:pool_tag`, Finch 0.22) for uploads/exports so they can't starve the JSON routes.

## 8. Per-route telemetry

- Phoenix router events (`[:phoenix, :router_dispatch, …]`) and OpentelemetryPhoenix's span renaming to `"METHOD route"` (opentelemetry_phoenix.ex:159) **don't fire for proxied requests**, because the proxy halts before the router.
- `[:phoenix, :endpoint, :stop]` (`Plug.Telemetry`) still fires, but it is emitted from `register_before_send`, i.e. at `send_chunked` = **time to first byte** for streamed responses (plug/telemetry.ex).
- `[:bandit, :request, :stop]` fires at the end with `duration`, `req_body_bytes`, `resp_body_bytes`, `resp_start_time` and `resp_end_time`, plus the final `conn` in its metadata (bandit/telemetry.ex:31-62). Admin already attaches `opentelemetry_bandit` 0.3.0 to it.
- Finch emits `[:finch, :request | :queue | :connect | :send | :recv, :start | :stop | :exception]` with the `Finch.Request` in its metadata (finch/telemetry.ex). `Finch.Request` has a `private` map (Req exposes it as `:finch_private`), so a route label can travel to queue/recv timings, separating "waiting for a pool connection" from "core is slow".
- Recommendation:
  1. Label every proxied request with its **route template** from the core inventory (e.g. `GET /api/items/:id`), never the raw path, which has unbounded cardinality. `put_private(conn, :core_proxy_route, label)`.
  2. Wrap the call in `:telemetry.span([:admin, :proxy, :request], %{route:, method:}, …)`. Its stop metadata carries `status` and an `outcome` (`:ok | :upstream_timeout | :upstream_error | :client_closed`). Feed it to `AdminWeb.Telemetry` metrics and LiveDashboard as `summary("admin.proxy.request.stop.duration", tags: [:route, :method, :status])`. That gives the per-route traffic log the map needs for port ordering.
  3. Call `OpenTelemetry.Tracer.update_name("#{method} #{label}")` and set `http.route` on the current Bandit span. Inject `traceparent` into the upstream headers (`:otel_propagator_text_map.inject/1`) if core gets tracing.

## Open questions this research does not settle

- Whether admin becomes the public entry point for core's domain, which requires `COOKIE_DOMAIN` and CORS to line up, or only for some hosts. That belongs to the proxy-design / CORS item in #312.
- Whether to turn off Bandit response compression globally or per proxied response (section 3).
- Exact per-route timeout and pool-tag table: derive it from the core inventory and early proxy logs.

## Sources

- Admin: `mix.exs`, `mix.lock`, `config/config.exs`, `config/runtime.exs`, `lib/admin_web/endpoint.ex`, `lib/admin/application.ex` (read only).
- Locked dependency sources in `deps/`: `req/lib/req/{finch.ex,steps.ex,response_async.ex,request.ex}` + CHANGELOG; `finch/lib/finch.ex`, `finch/lib/finch/{http1/conn.ex,http1/pool.ex,http2/pool.ex,telemetry.ex}` + CHANGELOG; `mint/lib/mint/http1.ex`; `bandit/lib/bandit.ex`, `bandit/lib/bandit/{adapter.ex,compression.ex,pipeline.ex,telemetry.ex,http1/handler.ex,http1/socket.ex,http2/stream.ex,websocket/handshake.ex,websocket/connection.ex}`; `plug/lib/plug/{conn.ex,parsers.ex,rewrite_on.ex,telemetry.ex}`; `websock/lib/websock.ex`; `websock_adapter/lib/websock_adapter.ex`; `thousand_island/lib/thousand_island.ex`; `opentelemetry_bandit`, `opentelemetry_phoenix`.
- Hexdocs: [Req](https://hexdocs.pm/req/0.6.2/), [Finch](https://hexdocs.pm/finch/0.23.0/Finch.html), [Mint](https://hexdocs.pm/mint/1.9.0/Mint.HTTP1.html), [Bandit](https://hexdocs.pm/bandit/1.10.4/Bandit.html), [Plug.Conn](https://hexdocs.pm/plug/1.20.2/Plug.Conn.html), [WebSockAdapter](https://hexdocs.pm/websock_adapter/0.5.9/WebSockAdapter.html), [Mint.WebSocket 1.0.6](https://mint-web-socket.hexdocs.pm/Mint.WebSocket.html), [ReverseProxyPlug 3.0.5](https://reverse-proxy-plug.hexdocs.pm/readme.html).
- GitHub: [tallarium/reverse_proxy_plug](https://github.com/tallarium/reverse_proxy_plug) `lib/reverse_proxy_plug.ex`, `lib/reverse_proxy_plug/http_client/adapters/req.ex`; [mwhitworth/reverse_proxy_plug_websocket](https://github.com/mwhitworth/reverse_proxy_plug_websocket) `mix.exs`; [jshttp/forwarded](https://github.com/jshttp/forwarded/blob/master/index.js).
- Core (local checkout): `src/fastify.ts`, `src/services/action/action.service.ts`, `src/services/auth/plugins/passport/plugin.ts`, `src/services/item/plugins/file/itemFile.controller.ts`, `src/services/item/plugins/thumbnail/itemThumbnail.controller.ts`, `src/services/item/plugins/importExport/importExport.controller.ts`, `src/services/auth/plugins/magicLink/magicLink.controller.ts`, `src/services/file/utils/constants.ts`; admin branch `310-core-route-inventory` `docs/core-inventory/README.md`.
