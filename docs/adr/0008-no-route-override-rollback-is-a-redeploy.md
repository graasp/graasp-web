# No Route Override: rolling back a Ported Route is a redeploy

A Ported Route goes back to core by reverting the change and deploying again. There is no Route Override: no database row, no admin screen, no per-request lookup in the proxy plug. Whether a route is ported is decided by `AdminWeb.Router` alone, as ADR 0004 already says. This replaces the Route Override in ADR 0004 and the named override group in ADR 0006.

Decided in graasp-web#323 (porting recipe), amending ADR 0004 (proxy) and ADR 0006 (websockets).

## Considered options

- **Keep the Route Override** as ADR 0004 decided, for rollback within seconds without a deploy: rejected. The client SPAs ship in admin's image, so a redeploy rolls back admin and the client together and the two can never disagree. The override would cost a table, an admin screen, a cached lookup on every `/api` request, and a named group for the Websocket Wave, all to save the few minutes a redeploy takes.

## Consequences

- **Rollback** of a route group is a revert PR plus a deploy. Core keeps the code of every route until it is shut down, so a reverted route is served by core again straight away.
- **No deletion in core per group.** Core's code for a ported route stays until core is shut down, so reverting is always possible.
- **Websocket Wave flip**: the wave ships in one deploy that ports `/api/ws` and its 17 publishers, and the ALB rule for `/api/ws` moves to admin right after that deploy. Events published in between are lost, which ADR 0006 already accepts (delivery is fire and forget). Rollback is the reverse: move the ALB rule back, then revert the deploy.
- **Production safety net**: the contract tests before merge (ADR 0007), plus the per-route telemetry span (ADR 0004) after deploy.
