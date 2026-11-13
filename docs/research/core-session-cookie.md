# Research: decrypting core's session cookie in Elixir

Answers graasp/graasp-web#314 (part of the wayfinder map #312).

**Short answer.** Yes, both ways. Core's session cookie is a libsodium
`crypto_secretbox_easy` (XSalsa20-Poly1305) box around a JSON document,
`{"__ts": <unix seconds>, "passport": "<account uuid>"}`. It is keyed directly
by the 32-byte `SECURE_SESSION_SECRET_KEY` (hex), with no key derivation. Given
the same key, admin can decrypt it with no call to core. Admin can also mint a
cookie that core accepts. A throwaway round trip (core's own plugin to Elixir
and back, see [Verification](#verification)) confirmed both directions.

Sources: core at commit `98fa6685` (2026-11-13), `@fastify/secure-session`
8.3.0, `@fastify/passport` 3.0.2, `@fastify/cookie` 11.0.2 and `cookie` 1.1.1
(core's `node_modules`), `sodium-native` 5.1.0. Paths below are relative to
`~/github/graasp/core` unless noted otherwise.

## 1. How core configures the cookie

`src/services/auth/plugins/passport/plugin.ts`:

```ts
.register(fastifySecureSession, {
  key: Buffer.from(SECURE_SESSION_SECRET_KEY, 'hex'),
  cookie: { domain: COOKIE_DOMAIN, path: '/', secure: PROD || STAGING,
            httpOnly: true, maxAge: SECURE_SESSION_EXPIRATION_IN_SECONDS },
  expiry: MAX_SECURE_SESSION_EXPIRATION_IN_SECONDS,
})
.register(fastifyPassport.initialize())
.register(fastifyPassport.secureSession());
```

- `SECURE_SESSION_SECRET_KEY` is a required env var (`src/config/secrets.ts`).
  It holds 64 hex characters, which decode to 32 raw bytes. Because `key` is
  given, the `secret`+`salt`/`crypto_pwhash` path in secure-session is **not
  used** (`index.js` lines 62-89 run only when there is `secret` and no `key`).
- `SECURE_SESSION_EXPIRATION_IN_SECONDS = 604800` (7 days) becomes the cookie's
  `Max-Age`.
- `MAX_SECURE_SESSION_EXPIRATION_IN_SECONDS = 15552000` (180 days) becomes
  secure-session's server-side `expiry`, checked against `__ts`.
- `COOKIE_DOMAIN` is a required env var (`src/utils/config.ts:36-40`).
- No `sessionName`/`cookieName` is set, so both default to **`session`**
  (`index.js:51-52`).
- No `signed: true`, so the `@fastify/cookie` signature is not used. (The
  `@fastify/cookie` secret that secure-session registers is
  `crypto_generichash(key)` in hex, `index.js:111-119,236-239`. It is irrelevant
  to this cookie.)

### Cookie attributes on the wire

`@fastify/cookie`'s `setCookie` merges `{ sameSite: 'lax' }` under the options
(`@fastify/cookie/plugin.js:14`). The serializer in `cookie/dist/index.js`
(`stringifySetCookie`, lines 135-180) writes them in this order. Here is a real
header produced by core's plugin with a throwaway key:

```
session=<value>; Max-Age=604800; Domain=<COOKIE_DOMAIN>; Path=/; HttpOnly; Secure; SameSite=Lax
```

- `Secure` appears only when `NODE_ENV` is production or staging.
- There is no `Expires` attribute, only `Max-Age`.
- On `request.session.delete()` (logout and account deletion), the same cookie
  is re-sent with `''`, `Max-Age=0` and `Expires=Thu, 01 Jan 1970 …`
  (`secure-session/index.js:276-285`).

## 2. Exact value format

From `secure-session/index.js`, `encodeSecureSession` (lines 216-230) and
`decodeSecureSession` (lines 146-212):

```
value      = encodeURIComponent( base64(box) + ";" + base64(nonce) )
box        = crypto_secretbox_easy(json, nonce, key)   // = MAC(16) || ciphertext
nonce      = 24 random bytes (randombytes_buf), fresh on every Set-Cookie
key        = the 32 bytes of hex-decoded SECURE_SESSION_SECRET_KEY
json       = JSON.stringify(sessionObject)
```

- **Algorithm.** `crypto_secretbox_easy` is XSalsa20 encryption with a Poly1305
  MAC. Combined mode writes the 16-byte tag *before* the ciphertext
  ([libsodium docs](https://doc.libsodium.org/secret-key_cryptography/secretbox)).
  Key is 32 bytes, nonce 24, MAC 16.
- **Base64 variant.** This is standard base64 (`+`, `/`) with `=` padding, from
  Node `Buffer.toString('base64')`. Node's decoder also tolerates URL-safe
  input and missing padding. An Elixir decoder should use `Base.decode64/2`,
  which is strict, standard alphabet, padded. That matches what core emits.
- **Separator.** Ciphertext comes first, then `;`, then the nonce.
- **URL encoding.** The `cookie` serializer runs `encodeURIComponent` on the
  value (`cookie/dist/index.js:140,144`). On the wire, `+` `/` `=` `;` therefore
  appear as `%2B` `%2F` `%3D` `%3B`. The parser runs `decodeURIComponent` only
  when the value contains `%` (`decode`, line 334). Admin must percent-decode
  before splitting on `;`. Plug does **not** do this for you:
  `Plug.Conn.Cookies.decode/1` returns raw values (`deps/plug/lib/plug/conn/cookies.ex`),
  so call `URI.decode/1` on `conn.req_cookies["session"]`. When issuing, admin
  must percent-encode the value, for example with `URI.encode_www_form/1`.
  Base64 has no spaces, so its `+`-for-space rule never applies.
  `put_resp_cookie/4` writes the value as given.
- **Decode failures are silent.** Core treats a missing `;`, a nonce that is not
  24 bytes, ciphertext shorter than 16 bytes, a MAC failure or an expired
  `__ts` as "no session" and starts an empty one. It never returns an error to
  the client. `JSON.parse` of a verified box is not guarded.
- **Key rotation.** secure-session accepts an array of keys. It tries each one
  to decrypt, always encrypts with `key[0]`, and re-issues the cookie when a
  non-first key matched (`index.js:187-194,227`). Core passes a single key
  today, but this is the built-in route for rotating the key during migration.

## 3. Payload: what passport stores

Plaintext JSON observed from the round trip:

```json
{"__ts":1794561605,"passport":"0f0a3ae8-1111-4222-8333-444455556666"}
```

- **`passport`** holds the **account id** (UUID string) and nothing else. The
  serializer in `plugin.ts` returns `user.account.id`. `SecureSessionManager`
  stores it under the key `passport`
  (`@fastify/passport/dist/session-managers/SecureSessionManager.js`). Guests
  work the same way: `POST /items/:id/login` sets
  `session.set(SESSION_KEY, bondMember.id)` with `SESSION_KEY = 'passport'`
  (`src/services/itemLogin/itemLogin.controller.ts:101`,
  `src/services/auth/plugins/passport/constants.ts`). Members and guests are
  both rows in `account`. The deserializer runs
  `accountRepository.get(db, uuid)`.
- **`__ts`** is a secure-session internal: unix **seconds**, set on creation and
  refreshed by every `set`/`touch`/`regenerate`/`delete` (`Session` class,
  `index.js:303-356`). The server rejects the cookie when
  `(__ts + expiry) * 1000 <= Date.now()`, with `expiry` = 180 days.
- There is no other field: no expiry claim, no roles, no CSRF token. Core
  declares `SessionData { passport: string }` in
  `src/@types/declarations.d.ts`. `@fastify/flash` is registered by
  `passport.initialize()` but core never calls `request.flash`. `messages` and
  `returnTo` are written only when the matching passport options are used,
  which core does not do.
- **Key order** is `__ts` then `passport`. That is insertion order: the
  constructor adds `__ts`, then passport sets its key. Core ignores order when
  reading.
- After logout, `passport` is set to `undefined`. `JSON.stringify` drops it, so
  a logged-out but undeleted session is `{"__ts":…}`.

## 4. Lifetime: what actually happens (note for #320)

The comment in `plugin.ts` says the 180-day `expiry` is a hard cap after which
the user "must re-authenticate". **The code makes it a sliding window
instead.**

1. `fastifyPassport.secureSession()` adds a global `preValidation` hook that
   runs the built-in `session` strategy (`Authenticator.js:72-75`). That hook
   deserializes the account on every request. When the account is gone, it
   calls `logOut`, which re-issues the cookie without `passport`
   (`strategies/SessionStrategy.js`). On success it calls `pass()`, which does
   not re-issue the cookie.
2. The `isAuthenticated` preHandler (`preHandlers.ts`), used by about 41 route
   files, runs the custom `strict-session` strategy. That strategy calls
   `done(null, user)`, which is passport **success**. `AuthenticationRoute.js`
   then calls `request.logIn(user)`, and `SecureSessionManager.logIn` calls
   `session.regenerate([...])` and `session.set('passport', id)`. Both touch
   `__ts`, so `onSend` emits a **new cookie with a fresh nonce, a fresh
   `__ts` and a fresh `Max-Age=604800`**.
3. `optionalIsAuthenticated`, used by public reads and the websocket upgrade,
   uses the plain `session` strategy, so it does **not** renew the cookie.

The net behaviour is that a session lives as long as the browser hits an
`isAuthenticated` route at least once every 7 days (browser-side `Max-Age`).
The 180-day `__ts` check only bites for clients that ignore `Max-Age`. If admin
ports `isAuthenticated` routes and the contract tests compare `Set-Cookie`,
admin must reproduce this: re-issue the cookie with a fresh `__ts` on each
strictly authenticated request. Otherwise users get logged out 7 days after
their last request to a route core still serves, as more and more traffic
moves to admin. Separately, the team should decide whether the documented
"hard cap" was ever intended. Changing it would break the contract.

## 5. Elixir options

OTP `:crypto` has no XSalsa20 (OpenSSL has no Salsa20 family). `:crypto` has
`chacha20_poly1305`, which is a different construction, and `:crypto.mac(:poly1305, …)`.
A pure-`:crypto` secretbox is not available without hand-writing
HSalsa20/XSalsa20. Libraries checked on hex.pm on 2026-11-13:

| Library | Kind | Latest | API | Notes |
|---|---|---|---|---|
| [`kcl`](https://hex.pm/packages/kcl) | pure Elixir (deps `salsa20`, `poly1305`, `curve25519`, `ed25519`) | 1.5.2 (2026-10) | `Kcl.secretbox(msg, nonce, key) :: binary`, `Kcl.secretunbox(box, nonce, key) :: binary \| :error` | No NIF and no system libsodium. **Verified byte-compatible with core both ways.** It is slower than C and not audited as constant-time. That is acceptable for a ~100-byte payload per request. |
| [`enacl`](https://hex.pm/packages/enacl) | NIF to system libsodium | 1.2.1 (2021-07) | `:enacl.secretbox(msg, nonce, key)`, `:enacl.secretbox_open(box, nonce, key) -> {ok, msg} \| {error, failed_verification}` | It is the real libsodium, but needs `libsodium-dev` in the build and runtime images. There has been no release since 2021, and it was not tried here. |
| [`libsalty2`](https://hex.pm/packages/libsalty2) | NIF to libsodium | 0.3.0 (2021-12) | wrapper | It is unmaintained. Avoid. |

Use `:crypto.strong_rand_bytes(24)` for the nonce when issuing. Use
`Plug.Crypto.secure_compare` only if you ever compare raw values. The MAC check
lives inside `secretunbox`.

**Recommendation:** use `kcl` for the read path (a plug that maps the
`session` cookie to `account_id`, then loads the account). It keeps the Docker
image free of native libsodium. If profiling later shows the pure-Elixir
Salsa20 matters, swap in `enacl` behind the same small module. The format is
identical.

## 6. Can admin issue a cookie core accepts?

**Yes.** Encrypt `{"__ts": now_seconds, "passport": account_id}` with a fresh
24-byte nonce under the same key, then serialize as in §2. Core's own
`decodeSecureSession` then yields `session.get('passport') == account_id`, and
the `session` strategy deserializes the account. A wrong key yields an empty
session (verified). This lets session issuance (login, magic link, guest item
login, logout via `Max-Age=0`) be ported last, as the map plans, while either
side reads and writes the same cookie in the meantime. Requirements:

- Admin gets the **same** `SECURE_SESSION_SECRET_KEY` (and `COOKIE_DOMAIN`) as
  core. Refer to it by name only, never copy values. During a rotation, both
  sides must try every key and encrypt with the newest one.
- Admin must serve under a host covered by `COOKIE_DOMAIN`, or the browser will
  not send the cookie. The proxy design (#319) settles this.
- Emit identical attributes: `Max-Age=604800; Domain=…; Path=/; HttpOnly;
  [Secure;] SameSite=Lax`. Phoenix's built-in `Plug.Session` cookie store
  **cannot** be reused for this cookie. It uses its own
  `Plug.Crypto.MessageEncryptor` format and would fight over the name. The
  `session` cookie must be read and written by a dedicated plug with a distinct
  name from admin's own Phoenix session cookie (`_admin_key`, set in
  `lib/admin_web/endpoint.ex`).

## Verification

This was a throwaway check outside the admin repo, with a random key and no
real secrets.

1. A script loaded core's own `fastify` + `@fastify/secure-session` from
   `~/github/graasp/core/node_modules`, set `passport` to a dummy UUID, and
   captured the `Set-Cookie` header shown in §1.
2. A standalone `elixir` script (`Mix.install([:kcl, :jason])`) percent-decoded
   the value, split it on `;`, base64-decoded both parts and called
   `Kcl.secretunbox/3`. It got the JSON in §3 back. Flipping one ciphertext bit
   returned `:error`.
3. The same script built a new cookie with `Kcl.secretbox/3`, a fresh nonce
   and a current `__ts`. Core's plugin decoded it to the same `passport` UUID.
   With a different key, core returned an empty session.
