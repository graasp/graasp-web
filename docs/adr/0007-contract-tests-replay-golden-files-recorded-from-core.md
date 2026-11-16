# Contract tests replay golden files recorded from core

A Ported Route proves it keeps core's contract by replaying **Golden Files** recorded from core. A recorder script runs each **Scenario** against core and saves what core did. Admin's tests replay the same requests against admin and compare the results. Core only has to run when a scenario is recorded. CI replays only, so the tests keep working after core is shut down.

Decided in graasp-web#322, building on ADR 0003 (Ash), ADR 0004 (proxy), ADR 0005 (session) and ADR 0006 (websockets).

## Considered options

- **Run core and admin side by side in CI** and compare each request's answers live: rejected. Admin's CI would need Node, core's dependencies and Redis until the very end, and the tests would stop working when core is shut down. Since core's API is frozen, recording once gives the same guarantee.
- **Rewrite core's jest tests in ExUnit** for each route group: rejected. The expectations would be written by hand, nothing would check them against core, and the copies would drift.
- **Check only against `openapi.json`**: rejected. It covers response shapes, not status codes, side effects or permission outcomes.
- **Shadow traffic** (the proxy mirrors real requests to both backends and logs the differences): not part of the harness. Mirroring writes would apply them twice. Reverting and redeploying is the production safety net (ADR 0008).

## Consequences

- **Scenarios are data**, kept in `test/contract/scenarios/<route group>/`. Each one has a seed in core's `seedFromJson` shape (so core's test seeds can be copied over), an Actor, steps, canned responses for external services, and approved deviations. Steps are HTTP requests, or the websocket steps `ws_open`, `ws_send` and `ws_expect`, interleaved.
- **The recorder** is a ts-node script in `test/contract/recorder/`. Like the inventory generator, it boots `../core` in-process and calls `app.inject`. Developers run it by hand. It needs Postgres, plus Redis only for websocket scenarios. Each golden file records the core commit it came from.
- **Seed by snapshot**: the recorder seeds with core's own `seedFromJson` and stores the resulting rows in the golden file as the before state. Admin inserts those rows verbatim, with the same ids. There is no Elixir port of the seeder.
- **Real credentials**: the recorder issues a real `session` cookie (and a real App Token for app scenarios), signed with test secrets shared with admin's test config. Replay therefore goes through ADR 0005's real cookie path.
- **What a step checks**: the status code, the JSON body, an allowlist of headers (`content-type`, `location`, CORS, and `set-cookie` name and attributes but not the encrypted value), the diff of every table except migration bookkeeping (including `action` rows), sent emails (recipient, template, key variables), storage calls, outgoing calls to external services, and the frames each open socket received. Jobs and search-index writes are left to the background-jobs decision.
- **Normalisation**: uuids, timestamps, tokens and hashes created during the scenario are replaced by placeholders, and the same value always gets the same placeholder, so relationships are still checked (the response id is the id of the inserted row). Arrays are ordered unless the scenario marks a path as unordered. Database rows are compared as sets keyed by primary key. Frames are compared per socket, in order. Timing is ignored: replay waits for the expected frames with a timeout, then asserts that no extra frames arrived.
- **External services** (OpenAI, etherpad, reCAPTCHA, `fetch`, S3) get the same canned responses on both sides: stubbed clients in the recorder, Mox in admin.
- **Approved Deviations** are declared per scenario and must cite the ADR that accepted them: ADR 0003's three permission cases, and ADR 0006's app topics answering `NOT_FOUND`. A deviation that cites no ADR is rejected. One that no longer matches anything fails the test. A deviation can change the body, an error message or a frame, never the status code. A different status code needs a new ADR.
- **Replay** runs as ExUnit tests tagged `:contract`, part of `mix test`, through the full endpoint (proxy plug, router, error renderer). In tests the proxy refuses to forward. A scenario whose route still reaches the proxy is reported as **pending**, not failed. Once a route is ported, all of its scenarios must pass.
- **Recorded before porting**: a route group's golden files are recorded first and become the acceptance criteria of its port issues.
- **Coverage**: a gate test fails when a Ported Route in the router has no scenario, or a scenario has no golden file. The expected minimum is the happy path, every auth outcome the route can give, and the validation branches core's jest tests cover. That minimum is enforced by the porting recipe and review, not mechanically.
