# Admin proxies core from the endpoint, and the router decides what is ported

All of core's API traffic (`/api/*`) goes through admin. A hand-written plug in `AdminWeb.Endpoint`, placed right after `Plug.Telemetry` and before the parsers, `MethodOverride`, `Head` and the session, decides for each request: if `AdminWeb.Router` has a route for it under `scope "/api"`, admin serves it; otherwise the plug streams it to core unchanged. Porting a route and switching it to Elixir are the same change. A **Route Override**, a database row edited in the admin UI, sends a ported route back to core without a deploy.

Decided in graasp-web#319, building on the reverse-proxy research (graasp-web#315) and the production-traffic research (graasp-web#317).

## Considered options

- **Proxy as a router `forward`**: rejected. By the time the router runs, `Plug.Parsers` has consumed JSON and multipart bodies (core accepts 1 GB uploads) and `Plug.Head` has turned HEAD into GET.
- **A switch table kept apart from the router** (config or database listing the ported routes): rejected. It can say a route is ported when the router doesn't serve it, or the other way round. Using the router as the source of truth leaves one place to change.
- **Router only, rollback by reverting the deploy**: rejected as too slow under incident pressure. Core and admin share the database and write identical `action` rows, so sending a route back to core is always safe. Only speed matters, and a database row takes effect on every task in seconds.
- **`reverse_proxy_plug`**: rejected in graasp-web#315. It buffers whole request bodies and doesn't proxy websockets.

## Consequences

- **The proxy is a transparent byte pipe.** It never follows redirects and never retries. It streams both bodies, drops hop-by-hop headers, keeps `Host`, `Origin`, `Authorization` and `Cookie`, and passes every `Set-Cookie` and CORS header through verbatim. Bandit compression is off for proxied responses, so core's `content-encoding` and `content-length` survive.
- **X-Forwarded-For**: the proxy appends its peer address. Core geolocates actions from the leftmost entry (`@fastify/forwarded(...).pop()`), which the ALB has already set to the client IP.
- **Pools and timeouts**: uploads and exports use their own Finch pool with a long `receive_timeout`. Everything else uses 15 s, with overrides per route template.
- **Ported routes** go through a `:core_api` pipeline: JSON parsing, no Phoenix session, no CSRF, and a hand-written CORS plug that reproduces core's rules exactly (the apex and `*.graasp.org` regex, credentials, app-publisher origins on app routes).
- **Telemetry**: every `/api` request, proxied or ported, runs in a `[:admin, :proxy, :request]` span tagged with the core route template (from a module generated off `docs/core-inventory/routes.json`), method, status, backend (`core`/`admin`) and duration. That span is the data for ranking ports and finding dead routes. A path that matches no template is tagged `route=unknown`, which shows drift in the inventory.
- **Core unavailable**: connection errors return 502 and timeouts 504, both in core's Fastify error shape (`{statusCode, error, message}`). There is no circuit breaker, and ported routes keep working. Maintenance gating for `/api` moves from the ALB into the plug as a config flag.
- **Cutover**, each step undone by reverting one ALB rule, dev before prod:
  1. Give admin a private route to core (Service Connect plus a security-group rule) and repoint `backend_origin`, so admin's own calls to core don't loop back through the ALB into admin.
  2. Ship the proxy dark.
  3. Delete ALB rule 7, so apex `/api/*` reaches admin (the SPA's same-origin OpenAPI layer).
  4. After a soak, point the `api.<env>` rules at admin (legacy SPA calls, apps, library, mobile). `api.<env>` stays forever.
  - Websocket paths (`/api/ws`, `/api/items/pages/:id/ws`) stay on core through higher-priority ALB rules until the websocket strategy is decided.
- **Capacity**: admin stays a single task with no autoscaling, and core drops from 2 tasks to 1. A single admin task then serves all API traffic and is a single point of failure for it; we accept that.
