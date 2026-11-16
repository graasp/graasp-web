# Porting recipe for a route group

How to move one group of core's API routes into admin. Every group follows the same steps and becomes two ordinary `ready-for-agent` issues: **Scenarios** and then **Port**.

Read first: `CONTEXT.md` (Core migration terms), [`docs/core-inventory/README.md`](../core-inventory/README.md) and ADRs 0003 (Ash), 0004 (proxy), 0005 (session), 0006 (websockets), 0007 (contract tests) and 0008 (rollback by redeploy).

## Ground rules

- **The contract is frozen.** A Ported Route answers exactly as core does: same path, JSON shape, status codes, headers, cookies, `action` rows, emails and websocket frames. Only the Approved Deviations listed in an ADR are allowed (ADR 0003's three permission cases, ADR 0006's dropped app topics).
- **Plain controllers, Ash underneath.** Controllers and serializers are hand-written to reproduce core's shapes. Ash resources, actions and policies hold the domain logic and authorization. Don't use AshJsonApi: its JSON:API format doesn't match core's contract.
- **Core keeps its code.** Nothing is deleted in core when a group is ported, so a revert and redeploy always hands the route back to core (ADR 0008).

## What a route group is

- By default, **one module of the core inventory** (`## item/itemBookmark` in [`ROUTES.md`](../core-inventory/ROUTES.md)), so names match the inventory.
- **Publishers are split out.** A route that publishes on `/api/ws` never sits in an ordinary group: it belongs to the **Websocket Wave** (ADR 0006), the single group holding `/api/ws` and its 17 publishers.
- **Tiny modules merge** into a neighbour when they share resources (for example `tag` with `item/tag`).
- **One agent session per group.** A module too large for one session is split into reads and writes.
- **Job and search side effects**: a group with a Job or Search effect in the inventory waits for the background-jobs decision (graasp-web#326) before its issues are filed.

## Foundation

These are built once, before the first group. Every group's Port issue is blocked by all of them:

1. Ash in admin (ADR 0003, transition step 1).
2. The contract-test harness: recorder, replay and coverage gate (ADR 0007).
3. The `:core_api` pipeline with core's CORS rules, and the error renderer producing core's Fastify error shape (`{statusCode, error, message}`) with Ash's 401/403/404 mapping (ADR 0004, ADR 0005).
4. The Actor plug that decodes core's session cookie, plus the validated-member, member and guest account-check plugs (ADR 0005, ADR 0003).
5. The `action` recorder, writing rows identical to core's.
6. The proxy plug (ADR 0004).

Plugs for the rarer auth mechanisms are built by the first group that needs them, once, in `AdminWeb.CoreApi.Plugs`, never inlined in a controller:

- the App Token plug, with the first app group;
- the magic-link, password-reset and email-change token plugs and the captcha plug, with the auth groups;
- the admin shared secret and the header secret, with `meta` and search.

## Steps

### Scenarios issue

1. Write the group's Scenarios in `test/contract/scenarios/<group>/`: for **every route** in the group,
   - the happy path;
   - every auth outcome the route can give (from the inventory's auth column: no session, unvalidated member, guest, missing permission, missing item, ...);
   - every validation case covered by core's jest tests for that controller.
2. Record their Golden Files against `../core` with the recorder, from a named core commit.
3. Check that `mix test` reports every scenario as **pending**, not failed.

### Port issue

1. **Resources**: reuse the existing Ash resources. A table that no resource owns yet gets one with `migrate? false`, declaring core's constraint and index names (ADR 0003, transition step 2).
2. **Actions and policies** on those resources. Item access goes through the shared item policies (`authorize_with: :error` for 403/404). Add to the existing domain (Items, Memberships, Members, Apps, Chat, Publications, ...) and don't create a domain per group.
3. **Controller and serializer**: `AdminWeb.CoreApi.<Group>Controller` calls the domain's code interface with `actor:`, and `AdminWeb.CoreApi.<Group>JSON` reproduces core's response shape.
4. **Routes**: add them under `scope "/api"` in the `:core_api` pipeline. A route in the router is a Ported Route (ADR 0004), so there is no separate switch.
5. **Side effects**: `action` rows through the shared recorder, emails with core's recipient, template and variables, storage calls, and external calls behind Mox.
6. Make every scenario of the group pass.
7. Run `mix precommit`.

## Done criteria

**Scenarios issue** is done when:

- every route in the group has its happy path, each auth outcome and core's jest validation cases as scenarios;
- every scenario has a Golden File naming the core commit it came from;
- `mix test` shows them all as pending.

**Port issue** is done when:

- no scenario of the group is pending or failing;
- the coverage gate passes;
- any new Approved Deviation cites an ADR (a different status code is never a deviation; it needs a new ADR);
- `mix precommit` is clean.

The Port issue closes on merge. After deploy, the telemetry span should show `backend=admin` for the group's route templates. If something breaks in production, revert and redeploy (ADR 0008).

## Issue templates

File the Scenarios issue first, then the Port issue blocked by it and by the Foundation. Generate the route checklist from `docs/core-inventory/routes.json`.

### Scenarios: `<group>`

```markdown
## What to build

Contract-test Scenarios and Golden Files for the `<group>` route group, recorded from core, following docs/core-migration/porting-recipe.md ("Scenarios issue").

## Routes

- [ ] `<METHOD> <path>`: auth `<auth column>`, jest file `<core test file>`
- [ ] ...

## Acceptance criteria

- [ ] Each route has its happy path, every auth outcome it can give, and core's jest validation cases as scenarios in `test/contract/scenarios/<group>/`
- [ ] Each scenario has a Golden File recorded from core commit `<sha>`
- [ ] `mix test` reports them all as pending
```

### Port: `<group>`

```markdown
## What to build

Port the `<group>` route group to admin, following docs/core-migration/porting-recipe.md ("Port issue"). The Scenarios in `test/contract/scenarios/<group>/` are the specification.

## Routes

- [ ] `<METHOD> <path>`
- [ ] ...

## Notes

<new resources/tables, rare auth plugs to build, emails, storage or external calls, anything odd from the inventory>

## Acceptance criteria

- [ ] No scenario of `<group>` is pending or failing
- [ ] The coverage gate passes
- [ ] Any new Approved Deviation cites an ADR
- [ ] `mix precommit` is clean

## Blocked by

- Scenarios: `<group>`
- Foundation issues
```
