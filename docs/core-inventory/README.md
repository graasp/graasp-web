# Core inventory

A generated map of every HTTP route that core (the Node backend, [graasp/graasp](https://github.com/graasp/graasp)) exposes, and what each route does. It is the starting point for moving core's API into admin one route at a time.

| File | Contents |
|---|---|
| [ROUTES.md](ROUTES.md) | Every route by module: auth, tables written and read, side effects, service methods called |
| [INDEX.md](INDEX.md) | The same data reversed: for each table, websocket topic, email, job, storage call, search call or external service, the routes that reach it |
| `routes.json` | The raw data behind both files |
| `scripts/` | The generator |

Everything except this README is generated. Do not edit it by hand: regenerate it.

## Regenerating

```sh
DB_CONNECTION=postgres://$USER@localhost:5432/postgres docs/core-inventory/scripts/regenerate.sh [path-to-core]
```

The default core path is `../core`, next to this repo. Core needs its dependencies installed (`pnpm install`). It opens a Postgres connection while booting, so `DB_CONNECTION` must point at any reachable database. No data is read. Redis and Meilisearch do not need to run. The generated files record the core commit they were built from.

## How it works

1. **`dump-routes.ts`** boots core's Fastify app without starting the server and records every route through an `onRoute` hook: method, full path (with plugin prefixes), websocket flag, schema tags and the controller `file:line`. Auth is read from the route's `preHandler`s, matched by identity against core's exported passport handlers, the `matchOne(...)` role strategies and `captchaPreHandler`. A few inline checks are labelled by hand in `render.py` (`AUTH_OVERRIDES`).
2. **`trace-effects.ts`** walks each route's registration with the TypeScript type checker. It follows every call it can resolve into core's `src`: services injected through DI, repositories, interface implementations, and service hooks (`setPreHook`/`setPostHook` handlers, reached through `runPreHooks`/`runPostHooks`). Along the way it records:
   - **tables:** Drizzle table and view references. Arguments to `insert`/`update`/`delete` count as writes.
   - **websockets:** `WebsocketService.publish*` calls, as topic and event.
   - **emails:** `MailerService.send*` calls, labelled with the function that triggers them.
   - **storage:** `FileService` calls.
   - **search:** Meilisearch index writes and queries.
   - **jobs:** BullMQ `Queue.add` calls.
   - **external:** etherpad, OpenAI, Redis, and outgoing HTTP through `fetch`.
3. **`render.py`** writes the Markdown files.

## Limits

- The trace is **static and over-approximate**. It counts every branch a route could take, so a route that creates "an item" lists the effects of every item type. Read it as "may touch", not "always touches".
- Calls the checker cannot resolve are not followed: values typed `any`, callbacks passed by reference, and events other than the hook manager.
- Effects that run outside the request are not attributed to routes: BullMQ workers (`src/workers`), scheduled jobs, and the work done by queued jobs. Only the enqueueing is recorded.
- Captcha verification (a Google reCAPTCHA call) and passport strategies run in `preHandler`s and appear only in the auth column.

## What it shows (core `98fa66853`)

- **178 routes in 49 modules.** About 110 are item features.
- **102 routes write to the database.** `item` and `action` (the activity log) are each written by 33 routes, and `item_membership` by 25.
- **Side effects:** 24 routes publish to websockets, 16 send email, 36 enqueue jobs (mostly search reindexing), 46 touch file storage, 41 touch the search index, and 22 call external services.
- **3 websocket endpoints:** `/api/ws` (realtime updates through Redis) and the two collaborative page endpoints `/api/items/pages/:id/ws` and `/ws/read`.
- **Nine auth mechanisms:** session required or optional (with validated, member and guest checks), the app iframe JWT, a magic-link token, a password-reset token, an email-change token, captcha, the admin shared secret, and a header secret.
- **Routes with no auth check:** `/health`, `/status`, `/version`, `/maintenance/next`, `/logout`, `/app-items/list`, `/items/flags`, the two public short-link lookups, and `/items/collections/search/rebuild` (which checks a header secret in the handler).
- **Odd routes to look at when porting:** `DELETE /api/members/members/:id/delete` (its path) and `GET /api/items/collections/search/rebuild` (a write triggered by a GET).
- **Tables no route touches:**
  - admin's own tables: `admins`, `admins_tokens`, `publication_removal_notices`, `schema_migrations`
  - `item_export_request`, used only by the export worker
  - `category` and `item_category`, which look like leftovers from before tags. Candidates to drop rather than port.
