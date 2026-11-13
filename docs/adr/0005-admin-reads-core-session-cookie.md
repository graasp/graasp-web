# Admin reads core's session cookie, and Actor and App Token stay separate

On a Ported Route, admin decrypts core's `session` cookie itself (libsodium secretbox through `kcl`, with the shared `SECURE_SESSION_SECRET_KEY`) and loads the account it names as the **Actor**, without calling core. Apps calling with an **App Token** (core's app iframe JWT) get a separate struct that only app resources accept, so a token never reaches item operations. Authorization is entirely Ash policies, and both kinds of caller share one Effective Permission calculation that takes the account id as an argument.

Decided in graasp-web#320, building on the session-cookie research (graasp-web#314), ADR 0003 (Ash) and ADR 0004 (proxy).

## Considered options

- **Ask core on every request** (forward the cookie to the current-member route): rejected. It adds a hop to every ported request and depends on a route that will itself be ported.
- **A new admin-issued session**: rejected. The cookie is part of the frozen contract the legacy SPAs depend on.
- **One actor struct for both the session and the App Token**: rejected. An App Token is a grant for one app item's own resources (app data, settings, actions), not an account acting on items. Keeping the structs apart makes that limit structural: item resources accept only an Actor, app resources only an App Token.
- **Plugs mirroring core's preHandlers** (`isAuthenticated`, `matchOne(validatedMember)`, …): rejected in favour of Ash policies. The one contract detail they carried, 401 versus 403, is kept by the error renderer.

## Consequences

- **Decoding**: any failure (bad MAC, a `__ts` older than 180 days, an unknown or deleted account) means "no Actor", never an error, as in core. Plug does not percent-decode cookie values, so the decoder calls `URI.decode/1` itself.
- **Proxied routes are never decoded.** The proxy stays a byte pipe and validates nothing.
- **401 versus 403**: the `:core_api` error renderer turns an Ash `Forbidden` into 401 in core's error shape when there is no Actor (or, on app routes that require an account, an App Token without one), and leaves it as 403 otherwise. Frontends rely on 401 to send people to sign-in.
- **Sliding renewal**: a `:core_api` plug re-issues the cookie (fresh `__ts`, core's exact attributes: `Max-Age=604800`, `Domain=$COOKIE_DOMAIN`, `Path=/`, `HttpOnly`, `Secure`, `SameSite=Lax`) on every ported request with an Actor. Core renews only on strict-session routes, and renewing more often is invisible to clients. Without it, people who only reach ported routes would be signed out after 7 days.
- **App Token**: built only from `Authorization: Bearer`. App routes ignore the session cookie, as core does (`session: false`). The token's item, not the URL, is the item, because three app routes have no `:itemId`. `Admin.Apps.Token` becomes verify-only, and matching the token's item to the resource moves into policies.
- **Effective Permission** is one calculation on Item taking `account_id`, with one shared "at least *p* on this item" policy check. Item policies pass the Actor's id. App policies pass the App Token's account id on the token's item, so "item writers and admins can write app settings" is written once.
- **Library LiveViews** get the Actor from the same decoder through an `on_mount` hook (`assign :actor`, never mixed with `current_scope`). They read the cookie but never renew it, since a LiveView socket cannot set cookies.
- **Issuing sessions**: when the auth routes are ported (last), admin mints core's exact cookie with the same key. This lasts only until the legacy SPAs are removed. A LiveView-native session after that is a separate effort. Key rotation (decrypt with any listed key, encrypt with the first) is a follow-up.
