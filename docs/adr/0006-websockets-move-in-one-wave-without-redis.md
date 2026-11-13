# Websockets move in one wave, without a Redis bridge

Admin never publishes to or subscribes to core's Redis channel. Because there is no bridge, a Ported Route's websocket events only reach clients whose `/api/ws` socket is held by the same backend. So `/api/ws` and every Core Route that publishes on it move to admin together, in one **Websocket Wave**, late in the migration. The app topics are dropped. Page collaboration sockets never move, because pages are retired along with core.

Decided in graasp-web#321, building on the websocket research (graasp-web#316), ADR 0004 (proxy) and ADR 0005 (session).

## Considered options

- **Admin publishes core's exact JSON to `graasp-realtime-updates`** so Node-held sockets receive admin's events: rejected. It ties admin to core's Redis, and to its strict message schema, for the whole migration, and it needs new network access from admin to Redis.
- **`/api/ws` moves first and admin subscribes to the Redis channel** to relay events that core still publishes: rejected for the same Redis dependency, even though it would let publishers be ported one by one.
- **Core forwards its events to admin over HTTP**: rejected. It adds code to core, which is being shut down.
- **Proxying websockets through admin** (WebSockAdapter + Mint.WebSocket): rejected. Each websocket endpoint moves exactly once, so an ALB rule is enough.

## Consequences

- **The wave**: `/api/ws` plus the 17 publishing routes: chat (publish, update, delete, clear), memberships (create, invite, CSV upload, CSV template upload, update, delete) and the async item operations that send `item/member` feedback (delete, move, copy, recycle, restore, validate, export). A publisher must never be served by a different backend from the one holding the sockets, so none of them is ported before the wave and none stays on core after it.
- **Port order**: the wave comes after every route group that doesn't publish, and after the background-jobs decision (copy and export enqueue jobs). Only auth and session issuance come later.
- **Flip**: the wave ships dark, with each publisher's Route Override pointing at core. In one operation, the ALB rule for `/api/ws` moves to admin and the wave's overrides are cleared. A few seconds of lost events are accepted, since delivery is fire-and-forget today. Rollback is the reverse. Route Overrides therefore gain a named group, so the 17 overrides are toggled as one and never left half switched. Overriding a single publisher in the wave would silently drop its events.
- **App topics are dropped** (a fourth frontend-safe deviation, next to ADR 0003's three). On admin, subscribes to `app-data`, `app-settings` and `app-actions` get the standard unknown-topic `NOT_FOUND`, and the app routes never publish. Apps opt in to websockets and fall back to fetching. The topics also depend on the session cookie, which app requests will no longer carry (ADR 0005). The 7 app routes are therefore ordinary non-publishing routes and can be ported at any time.
- **Contract kept otherwise**: the same JSON protocol, topics, channels, body shapes and errors, including `NOT_FOUND` for the unregistered `mentions` topic and the `'websockets signed out'` error. Authorization happens once, at subscribe time, through the Ash Effective Permission check, with the Actor decoded from the cookie on the upgrade request.
- **Publish after commit**: ported publishers send their event once the transaction commits. Core's membership hooks fire inside the transaction. The change is invisible to the contract and removes a stale-refetch race.
- **Fan-out**: local `Phoenix.PubSub`, which is correct while admin runs a single task (ADR 0004). Scaling admin past one task first requires distributed PubSub (clustering) or a shared broker.
- **Pages**: `/api/items/pages/:id/ws` and `/ws/read` stay pinned to core by ALB rules and are retired along with core, together with the page feature. Until then, ported routes that write `page_update` rows (copy, CSV template upload) keep doing so as plain DB writes.
- **Redis**: admin never connects to it for websockets. Whether it connects for BullMQ is up to the background-jobs decision.
