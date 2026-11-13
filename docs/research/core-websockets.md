# Core's websocket protocol and Redis fan-out

Research for graasp/graasp-web#316 (wayfinder map #312). It answers how core's three websocket endpoints work, in enough detail to reimplement or bridge them from admin without changing what frontends see.

Sources: core v2.15.0 (`~/github/graasp/core`, branch `305-admin-owns-schema`), client v2.38.2, `@graasp/sdk` v5.18.0, `@graasp/apps-query-client` v3.7.5, `graasp-infrastructure` (HEAD 4b9919c), and `docs/core-inventory/INDEX.md` on `origin/310-core-route-inventory`. Paths below are relative to each repo. Core paths are under `core/src/`.

## TL;DR

- **Two separate protocols share one `ws` server.** `/api/ws` carries JSON pub/sub notifications ("realm `notif`"). `/api/items/pages/:id/ws` and `/api/items/pages/:id/ws/read` speak the binary Yjs protocol (y-websocket sync and awareness).
- **Only `/api/ws` uses Redis.** Every `websockets.publish` goes through one Redis pub/sub channel, `graasp-realtime-updates`, including messages meant for the publishing instance itself. Every core instance subscribes to that channel and forwards each message to its local sockets.
- **Anything that can `PUBLISH` to that Redis channel reaches Node-connected clients**, as long as the payload passes core's strict JTD schema (format below). Admin could therefore emit notifications for ported routes without core's involvement, or subscribe to the channel to serve clients itself.
- **Page collaboration has no cross-instance fan-out.** Yjs docs live in process memory, and their updates are persisted to the `page_update` table. Production runs 2 core tasks, and the infra code shows no sticky routing, so two editors on different tasks only meet through the database when a doc is reloaded. This is an existing limitation, and it looks like a bug.
- **Authorization happens once, at subscribe time** (or at the upgrade for pages), and is never re-checked. Unauthenticated sockets can connect to `/api/ws`, but every subscribe they send is rejected.

## 1. `/api/ws`: notification pub/sub

### Wiring

- `app.ts:26-63` registers `@fastify/websocket` once, then the websockets plugin under the `/api` prefix with `prefix: '/ws'` and `redis: { channelName: 'graasp-realtime-updates', connection: REDIS_CONNECTION }`. `REDIS_CONNECTION` is a required env var (`config/redis.ts:6`).
- `services/websockets/websocket.controller.ts:57-83`: `GET /ws` with `{ websocket: true, preHandler: optionalIsAuthenticated }`. `optionalIsAuthenticated` is passport's **Session** strategy only, so authentication comes from the session cookie (the MobileJwt line is commented out, `services/auth/plugins/passport/preHandlers.ts:22-25`). Unauthenticated connections are accepted, and `user` is undefined.
- Public URL: clients build `${WS_HOST}/ws`, where `WS_HOST = API_HOST.replace('http','ws')` (`client/src/config/env.ts:4`, `client/src/config/queryClient.ts:8`). In production the ALB rewrites `api.graasp.org/<path>` to `/api/<path>` (`graasp-infrastructure/main.ts:1055-1085`), so `wss://api.graasp.org/ws` reaches `/api/ws`. The apps client derives `WS_HOST` from `API_HOST` in the same way, and websockets are opt-in there (`enableWebsocket`, `graasp-apps-query-client/src/ws/index.ts`, `queryClient.ts:78-82`).

### Wire format (all text frames of JSON)

The protocol is documented in `services/websockets/API.md` and enforced by the AJV JTD schemas in `services/websockets/schemas/message.ts`. The TypeScript types come from `@graasp/sdk` (`Websocket.*`).

Client to server, discriminated on `action`. Every message carries `realm: "notif"`:

```jsonc
{ "realm": "notif", "action": "subscribe",     "topic": "<topic>", "channel": "<channel>" }
{ "realm": "notif", "action": "subscribeOnly", "topic": "<topic>", "channel": "<channel>" } // drop all other subs first
{ "realm": "notif", "action": "unsubscribe",   "topic": "<topic>", "channel": "<channel>" }
{ "realm": "notif", "action": "disconnect" }
```

JTD `properties` rejects unknown keys, so any extra field makes the message a parse failure.

Server to client, discriminated on `type` (`services/websockets/message.ts`):

```jsonc
// response to a subscribe/unsubscribe (request is echoed back)
{ "realm": "notif", "type": "response", "status": "success", "request": { ... } }
{ "realm": "notif", "type": "response", "status": "error", "error": { "name": "...", "message": "..." }, "request": { ... } }
// notification
{ "realm": "notif", "type": "update", "topic": "<topic>", "channel": "<channel>", "body": { ... } }
// info: schema exists, but no code path in core sends it
{ "realm": "notif", "type": "info", "message": "...", "extra": ... }
```

Error names are `ACCESS_DENIED`, `BAD_REQUEST`, `NOT_FOUND` and `SERVER_ERROR`, with fixed messages (`sdk/src/websockets/errors.ts`). An unparseable request gets `BAD_REQUEST` and no `request` field. A validator that throws a non-websocket error (for example core's item-not-found) has that error object serialized as-is, because the response schema sets `additionalProperties: true`. Expected shapes are pinned in `services/websockets/test/service-api.test.ts:181-193, 446-468`.

### Server semantics (`services/websockets/ws-service.ts`, `ws-channels.ts`)

- **Subscribe** (`ws-service.ts:74-120`): if there is no authenticated account, the reply is an error with `{ name: 'websockets signed out', message: 'not authorized' }`. Otherwise the server looks up the validator registered for `topic`. An unknown topic gives `NOT_FOUND`. It then runs `validate({ channel, member })`, where a throw means an error response. On success it creates the local channel `"<topic>/<channel>"` if needed, adds the socket, and replies with success.
- **Channel scoping**: the internal channel name is `${topic}/${channel}`. The literal channel `broadcast` is not scoped (`ws-service.ts:64-69`).
- **Unsubscribe** never re-validates. It replies with success, or with `NOT_FOUND` if the socket was not subscribed, and deletes the local channel once it is empty.
- **Heartbeat** (`ws-channels.ts`): every 30 s the server pings each socket and terminates any that did not answer the previous ping. It also garbage-collects empty channels. The client sends no keep-alive and does not reconnect (that code is commented out in `sdk/src/websockets/ws-client.ts`).
- **Client subscription lifecycle** (`sdk/src/websockets/ws-client.ts`): the client queues subscriptions made before the socket opens ("early"), sends `subscribe`, and moves a channel to "current" when the success response arrives. It sends one `subscribe` per channel however many handlers are registered, and `unsubscribe` when the last handler goes away. It only uses `subscribe` and `unsubscribe`, never `subscribeOnly` or `disconnect`.

### Topics, channels and authorization

| Topic | Channel | Validator (who may subscribe) | Registered at |
|---|---|---|---|
| `item/member` | member id | `channel === member.id` | `services/item/ws/item.hooks.ts:11-19` |
| `memberships/item` | item id | read access to the item (`assertAccessForItemId`) | `services/itemMembership/ws/hooks.ts:18-25` |
| `chat/item` | item id | read access to the item | `services/chat/chatMessage.controller.ts:51-55` |
| `app-data` | app item id | read access, and the item is an app | `services/item/plugins/app/appData/appData.controller.ts:49-56` |
| `app-settings` | app item id | read access, and the item is an app | `services/item/plugins/app/appSetting/appSetting.controller.ts:30-34` |
| `app-actions` | app item id | **admin** permission, and the item is an app | `services/item/plugins/app/appAction/appAction.controller.ts:26-34` |

Two topics are dead:

- `mentions` is declared in `services/chat/plugins/mentions/ws/events.ts`, and the client subscribes to it (`client/src/query/ws/hooks/mentions.ts`), but core never registers it. Those subscribes always get `NOT_FOUND`.
- The client constant `TOPICS.ITEM = 'item'` has no server counterpart.

### Redis fan-out (`services/websockets/multi-instance.ts`)

- Each instance opens two ioredis connections (pub and sub) and `SUBSCRIBE`s to `graasp-realtime-updates`.
- `WebsocketService.publish(topic, channel, body)` (`ws-service.ts:184-189`) builds the server `update` message and calls `dispatch`, which `PUBLISH`es this JSON:

```jsonc
{
  "realm": "notif",
  "channel": "<topic>/<channel>",        // or "broadcast"
  "data": { "realm": "notif", "type": "update", "topic": "<topic>", "channel": "<channel>", "body": { ... } }
}
```

- When a message arrives on the sub connection, it is parsed with the same strict JTD schema (`redisMessageSchema`). Invalid messages are logged and dropped. Valid ones go to `channelSend("<topic>/<channel>", data)` on the local sockets, or `broadcast` when `channel === "broadcast"`. Note that `broadcast` would iterate over *every* socket of the shared `fastify.websocketServer`, page Yjs sockets included, but nothing in core calls it.
- **The publishing instance also receives its own message through Redis.** No local short-cut is used (`publishLocal` exists but has no caller). Consequences: if Redis is down, no notifications go out at all, even with a single instance. And a channel with no local subscribers is simply a no-op.
- Delivery is fire-and-forget: Redis pub/sub keeps no history, so a client that is disconnected misses the event for good.

### Can something other than core publish? Yes.

The sub handler checks nothing except the channel name and the schema. There is no signature and no origin check. Any process with access to the same Redis can `PUBLISH graasp-realtime-updates '<json>'`, and every core instance will deliver it to its subscribed clients. Constraints the payload must meet:

- The top level has exactly `realm` (`"notif"`), `channel` (a string) and `data`. Extra keys are rejected.
- `data` must match `serverMessageSchema`. For an `update`, that means exactly `realm`, `type`, `topic`, `channel` and an optional `body` of any shape.
- The top-level `channel` must be `"<topic>/<channel>"`, because that is the local channel key. The inner `topic` and `channel` are what the client uses to route the message to handlers.
- Workers (`src/workers/`) and jobs (`src/jobs.ts`) never publish websocket events today. Only HTTP route handlers and service post-hooks do.

The reverse direction works too: a non-core subscriber (for example admin through Redix) can `SUBSCRIBE` to the same channel and receive every event core emits. Admin has no Redis client today (`mix.exs` has no `redix` dependency).

## 2. Events emitted by the 24 publishing routes

The route list comes from INDEX.md "Websocket publications". Every body below is the `body` of an `update` message. `*Raw` types are drizzle rows serialized with `JSON.stringify` (camelCase keys, ISO date strings).

| Topic / channel | Body | Routes (core file) |
|---|---|---|
| `chat/item` / itemId | `{ kind: 'item', op: 'publish'\|'update'\|'delete', message: ChatMessageRaw }`; `clear` has no `message` | `POST /api/items/:itemId/chat` (publish), `PATCH .../chat/:messageId` (update), `DELETE .../chat/:messageId` (delete), `DELETE .../chat` (clear). `services/chat/chatMessage.controller.ts:86,120,150,180`; event in `services/chat/ws/events.ts` |
| `memberships/item` / itemId | `{ kind: 'item', op: 'create'\|'update'\|'delete', membership: ItemMembershipRaw }` | create: `POST /api/items/:itemId/memberships`, `POST /api/items/:id/invite`, `POST /api/items/:id/invitations/upload-csv`, `POST .../upload-csv-template`; update: `PATCH /api/items/:itemId/memberships/:id`; delete: `DELETE /api/items/:itemId/memberships/:id`. Emitted from `ItemMembershipService` post-hooks (`services/itemMembership/ws/hooks.ts:35-77`). These hooks run inside the DB transaction, so the event can arrive before commit. For `create`, the channel is the last id in `membership.itemPath`. |
| `app-data` / itemId | `{ kind: 'app-data', op: 'post'\|'patch'\|'delete', appData }`. post and patch carry `addMemberInAppData(appData)`; delete carries the raw row. **Only sent when `appData.visibility === 'item'`.** | `POST/PATCH/DELETE /api/app-items/:itemId/app-data[/:id]` (`appData.controller.ts:73,90,107`) |
| `app-settings` / itemId | `{ kind: 'app-settings', op: 'post'\|'patch'\|'delete', appSetting: AppSettingRaw }` | `POST/PATCH/DELETE /api/app-items/:itemId/app-settings[/:id]` (`appSetting.controller.ts:64,84,104`) |
| `app-actions` / itemId | `{ kind: 'app-actions', op: 'post', appAction }`, with the member added | `POST /api/app-items/:itemId/app-action` (`appAction.controller.ts:47`) |
| `item/member` / acting member id | Success: `ItemOpFeedbackEvent` = `{ kind: 'feedback', op, resource: string[] /* requested ids */, result, errors: [] }`. Failure: `{ kind: 'feedback', op, resource, errors: [{ name, message }] }` with no `result`. Both shapes are built in `services/item/ws/item.events.ts`. | See below |

`item/member` feedback events are the asynchronous completion of the 202 or 204 routes. The handler replies first, then runs the work and publishes:

| op | Route | `result` on success | Source |
|---|---|---|---|
| `delete` | `DELETE /api/items?id=` (202) | `{ [id]: ItemRaw }` | `services/item/item.controller.ts:255-294` |
| `move` | `POST /api/items/move` (202) | `{ items, moved }` | `item.controller.ts:296-333` |
| `copy` | `POST /api/items/copy` (202) | `{ items, copies }` | `item.controller.ts:335-373` |
| `recycle` | `POST /api/items/recycle` (202) | the recycled items, as returned by the service | `services/item/plugins/recycled/recycled.controller.ts:73,82` |
| `restore` | `POST /api/items/restore` (202) | `{ [id]: ItemRaw }` | `recycled.controller.ts:116,124` |
| `validate` | `POST /api/items/:itemId/validate` | `{ [itemId]: item }` | `services/item/plugins/publication/validation/itemValidation.controller.ts:78,107` |
| `export` | `POST /api/items/:id/actions/export` (204) | `{ [itemId]: item }`; published only if the service returned an item | `services/item/plugins/action/itemAction.controller.ts:105,114` |

Count: 1 app-action + 3 app-data + 3 app-settings + 4 chat + 6 membership + 7 item feedback = **24 routes**, which matches INDEX.md. Nothing else in core calls `publish`.

## 3. Page collaboration: `/api/items/pages/:id/ws` and `/ws/read`

### Endpoints and auth (`services/item/plugins/page/page.controller.ts:60-118`)

| Endpoint | preHandler | Behaviour |
|---|---|---|
| `GET /api/items/pages/:id/ws/read` | `optionalIsAuthenticated`, then read access to the item (public items work signed out), then `type === 'page'` | Receive-only. No awareness. |
| `GET /api/items/pages/:id/ws` | `isAuthenticated`, `validatedMemberAccountRole`, then **write** permission, then `type === 'page'` | Bidirectional sync and awareness |

All checks run during the HTTP upgrade. A permission change made while a socket is open does not affect it.

### Protocol

The protocol is standard **y-websocket**. The server is adapted from `yjs/y-websocket-server/src/utils.js` (`setupWSConnection.ts:1`, `README.md`). Frames are binary (`binaryType = 'arraybuffer'`), encoded with lib0 varints:

- Message type `0` = sync (y-protocols `sync`: step 1, step 2, update). Type `1` = awareness (`constants.ts`).
- On connect, the server sends sync step 1. Writers also get the current awareness states (`setupWSConnection.ts:224-257`).
- The client is the stock `y-websocket` `WebsocketProvider(WS_HOST, 'items/pages/<id>/ws[/read]', doc)`, used through Lexical's `@lexical/yjs` CollaborationPlugin (`client/src/components/page/useYjs.ts:118-131`). The awareness state includes `{ name, color }`.
- The server pings every 30 s (`PING_TIMEOUT`) and closes a connection that did not pong. An unknown or invalid message closes with code 1003. A failure to load state closes all connections with 1011.
- On `/ws/read`, any client update is applied to the read doc, but it is only re-broadcast when its origin is the writer doc or the initial sync (`WSReadDoc`, `setupWSConnection.ts:131-167`). In effect it is read-only. Awareness messages are ignored there (`enableAwareness = false`).

### State and persistence

- Two in-memory maps per process: `docs` (writer `WSSharedDoc`) and `readDocs` (`WSReadDoc`), both keyed by page id (`setupWSConnection.ts:32-33`). Writer updates are applied to the read doc of the same process, if one exists. A doc is destroyed when its last connection closes.
- Persistence is the `page_update` table: `(item_id uuid FK→item ON DELETE CASCADE, update bytea, clock int)`, indexed on `item_id` (`drizzle/schema.ts:1152-1167`). Every Yjs update on a writer doc is appended as a new row with `clock + 1` (`page.service.ts:66-101`). `storeUpdate` is fire-and-forget, so its transaction is not awaited.
- Load (`PageItemService.getById`, `page.service.ts:50-64`) applies all rows in order. Above `PREFERRED_TRIM_SIZE = 500` rows, it writes the merged state as a new row and deletes the older ones, without awaiting the delete.
- Item copy merges the updates into a single row for the copy (`page.service.ts:76-81`, a post-hook in `page.controller.ts:25-29`). The upload-csv-template and copy routes write `page_update` this way, which is why INDEX.md lists them.
- `page_update.update` is an opaque Yjs update. Any server that speaks Yjs (Elixir has `y_ex`, a Yrs NIF) can read or write it.

### Multi-instance gap

Nothing ties a page's sockets to one instance, and Yjs updates do not go through Redis. Production runs `taskCount: 2` (`graasp-infrastructure/config.ts:134`), and the ALB target group in `main.ts` sets no stickiness. When two writers land on different tasks, each task holds its own `WSSharedDoc`: neither sees the other's edits live, while both append rows to `page_update`. The CRDT merges correctly on the next load, but the session is not collaborative. Readers have the same problem: a `/ws/read` socket only sees writers on its own task.

## 4. Implications for the migration (facts, not decisions)

- **Bridging `/api/ws` is cheap in both directions.** Admin can publish notifications for routes it ports by writing the exact Redis JSON above (`PUBLISH graasp-realtime-updates`). Clients connected to Node keep working with no change. Later, admin can own `/api/ws` itself: a raw WebSocket handler (e.g. `WebSock`/Bandit; Phoenix Channels speak a different wire protocol) that implements the four client actions and six validators, and `SUBSCRIBE`s to the Redis channel so that events core still publishes reach admin-held sockets. Ordering and delivery guarantees are no worse than today's.
- **Contract surface to freeze in contract tests**: the client actions, the response and error shapes (including the `'websockets signed out'` oddity and errors echoed as-is), the topic and channel names, the six body shapes above, the rule that app-data events are sent only for `visibility: 'item'`, and the 202-then-feedback pattern on `item/member`.
- **Pages are self-contained**: one table, the standard y-websocket protocol, no Redis. Porting them means speaking y-protocols in Elixir and reading and writing `page_update` with the same clock and trim rules. Running core and admin page sockets side by side for the same page would split sessions just as two core tasks already do.
- **Auth dependency**: all three endpoints authenticate with the session cookie only. Whatever #312 decides about admin recognising core's session applies to the WebSocket upgrade as well.

## Open questions

- Is the production split-session problem on pages known or observed? Sticky sessions on the ALB, or a Redis-backed Yjs relay, would fix it in core today, independently of the migration.
- Should the dead `mentions` topic be implemented or dropped? The contract says frontends see `NOT_FOUND` today.
