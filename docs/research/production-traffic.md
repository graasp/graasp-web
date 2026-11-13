# How production traffic reaches core and admin

Research for graasp/graasp-web#317, part of the map graasp/graasp-web#312 (migrate core into admin, with admin eventually proxying all API traffic to core).

**Question:** How do requests reach core and admin in production today, and what has to change for all API traffic to go through admin?

Sources are the local checkouts read on 2026-11-13. Paths are relative to `~/github/graasp/`. Secret values are not reproduced; variables are named only.

## Which infra repo is current

- **`graasp-infrastructure`** (CDKTF/Terraform on AWS) is the live definition. `main.ts` and `README.md` were modified on 2026-11-13, and the README documents the current deploy flow, including migrations run by the admin image (ADR 0002). It defines two stacks: `graasp-dev` (`dev.graasp.org`, default region) and `graasp-prod` (`graasp.org`, Zurich `eu-central-2`). There is no staging stack any more. (`graasp-infrastructure/main.ts` end of file)
- **`infra_2.0`** is an OpenTofu prototype for an Infomaniak (OpenStack + managed Kubernetes) cluster, untouched since 2026-04-14. It only declares a cluster, network and LB, with no application routing. It does not carry production traffic. (`infra_2.0/README.md`, `infra_2.0/main.tf`)
- **`graasp-deploy`** holds the older reusable GitHub Actions workflows and version manifests (`in-production/*.json`, last dated 2025). It does no routing. Only the `deploy-s3` action is still referenced, by the client's own (legacy) deploy workflow. (`graasp-deploy/README.md`, `client/.github/workflows/deploy.yml`)

## Topology in one picture

```
                 Route53 (zone per env, A/ALIAS records in IaC)
                               |
   +---------------------------+-------------------------------+
   |                                                           |
 CloudFront (S3 static only)                     One public ALB (HTTPS :443, HTTP :80 -> 301 https)
   apps.graasp.org     -> S3 apps bucket            host/path rules -> ECS Fargate target groups
   assets.graasp.org   -> S3 assets bucket          default action: 302 -> maintenance.graasp.org
   h5p.graasp.org      -> S3 h5p bucket
   maintenance.graasp.org -> S3 maintenance
```

CloudFront is **not** in front of core, admin or the library. It only fronts the four S3 website buckets (`makeCloudfront` origins are S3 website endpoints, GET/HEAD only). (`graasp-infrastructure/constructs/cloudfront.ts`, `main.ts` "S3 buckets" section)

Everything dynamic goes through one Application Load Balancer, in public subnets, with a single HTTPS listener whose default action redirects to `maintenance.<env>`. (`graasp-infrastructure/constructs/load_balancer.ts`)

## ALB listener rules (HTTPS listener)

Lower priority number wins. `<env>` is `graasp.org` in prod and `dev.graasp.org` in dev. Every rule except admin's and umami's also requires the maintenance-bypass header when the infra state is in maintenance (`ruleConditions` from `getMaintenanceHeaderPair`).

| Prio | Condition | Action | Source |
|---|---|---|---|
| 1 | Host `api.<env>` AND path `/api/*` | forward to **core** target group (container `core`, health `/health`) | `main.ts`, core `cluster.addService` |
| 2 | Host `api.<env>` (any path) | forward to **core** with URL rewrite `^/(.*)$` to `/api/$1` | `main.ts` `redirect-without-api-prefix-rule` |
| 4 | Host `etherpad.<env>` | forward to etherpad | `main.ts` |
| 5 | Host `umami.<env>` | forward to umami | `main.ts` |
| 7 | Host `<env>` (apex) AND path `/api/*` | forward to **core** | `main.ts` `single-origin-core-rule` |
| 8 | Host `<env>` (apex) | forward to **admin** (port 4000, health `/up`) | `main.ts`, admin `cluster.addService` |
| 9 | Host `collab.dev.graasp.org` (dev only) | forward to EC2 collab service | `main.ts` |
| 30 | Host `library.<env>` | forward to library (TanStack Start SSR, port 3000) | `main.ts` |
| 50 | Host `go.<env>` | 302 to `https://api.<env>/items/short-links/#{path}` | `load_balancer.ts` `setupRedirections` |
| 51-56 | Host `account`, `auth`, `player`, `builder`, `analytics`, `association` `.<env>` | 301 to apex `/<name>/#{path}` (association to `/about-us`) | `load_balancer.ts` |

Notes:

- The comment above rule 2 still says it is an HTTP redirect, but the code now uses the ALB `transform` / `url-rewrite`. Requests to `api.<env>/items/...` are forwarded, not redirected. The comment says this rule can "probably never" be removed, because legacy clients call the API without the `/api` prefix.
- Core is therefore reachable on two hosts: `api.<env>` (both with and without `/api`) and the apex `<env>/api/*`.
- `admin.<env>` has a Route53 record pointing to the ALB, but no listener rule matches it, so it falls through to the default maintenance redirect. Admin is served only on the apex. (`main.ts` "Create DNS entries")
- No idle-timeout or stickiness setting is configured on the ALB or the target groups, so ALB defaults apply (60 s idle timeout, no stickiness). Prod runs 2 core tasks (`config.ts`). Websocket fan-out goes through Redis pub/sub (channel `graasp-realtime-updates`). (`core/src/app.ts`)
- Meilisearch, iframely and redis are not behind the ALB. Admin is exposed in the ECS Service Connect namespace as `admin:4000`. **Core is not** exposed there (`internalNamespaceExpose` is `undefined` for the `graasp` service), and core's security group only accepts traffic from the ALB security group on `BACKEND_PORT`. (`main.ts`, `constructs/cluster.ts`)

## Core: CORS and cookies

- **API prefix:** all core routes, including the websocket plugin at `/api/ws`, are under `/api`. (`core/src/app.ts`)
- **CORS:** enabled only when `CORS_ORIGIN_REGEX` is set. Infra sets it to `envCorsRegex`, i.e. `^https?://(([a-z0-9]+\.)+)?graasp\.org$` in prod (with `dev\.` inserted in dev), so it matches the apex and every subdomain. Options: `credentials: true`, `maxAge: 7200`, methods HEAD/GET/POST/PATCH/PUT/DELETE/OPTIONS. (`core/src/fastify.ts`, `graasp-infrastructure/utils.ts`)
  - CORS is registered per route group (auth, member, item, tag, maintenance), not globally.
  - The **app routes** extend the allowed origins with every valid app origin from the database (`appService.getAllValidAppOrigins`, i.e. publisher origins). This list is loaded once at boot. (`core/src/services/item/plugins/app/app.controller.ts`)
- **Session cookie:** `@fastify/secure-session` (default cookie name `session`), `domain: COOKIE_DOMAIN`, `path: /`, `httpOnly`, `secure` in prod and staging, `maxAge` from `SECURE_SESSION_EXPIRATION_IN_SECONDS`, absolute `expiry` from `MAX_SECURE_SESSION_EXPIRATION_IN_SECONDS`. No `sameSite` is set, so browsers apply their default (Lax). (`core/src/services/auth/plugins/passport/plugin.ts`)
- Infra sets `COOKIE_DOMAIN` and `ETHERPAD_COOKIE_DOMAIN` to `.<env>` (e.g. `.graasp.org`). The core session cookie is therefore sent to **every** graasp.org host, including admin on the apex. (`graasp-infrastructure/main.ts` `backendEnv`)
- Other auth modes: Bearer JWT for apps (`jwtApps`, `APPS_JWT_SECRET`), and a shared-secret Bearer strategy for admin-to-core machine calls (`adminSharedSecret`, `ADMIN_SHARED_SECRET`). (`passport/plugin.ts`)
- **Client IP:** actions take the client IP as the *last* entry of `X-Forwarded-For` (`forwarded(request.raw).pop()`), which today is the one the ALB appended. Geolocation is derived from it. Core sets no `trustProxy`. (`core/src/services/action/action.service.ts`)
- The `Origin` header decides the action `view` (builder/player/...) via `ClientManager.getContextByLink`. (same file)

## Admin

- **Host:** `PHX_HOST` is the apex (`envDomain`), public port 443. LiveView `check_origin` is `["https://#{host}", "//#{host}"]`, apex only. (`config/runtime.exs`, `graasp-infrastructure/main.ts` `adminEnvironment`)
- **Session:** admin's own cookie is `_admin_key`, host-only (no domain), `same_site: "Lax"`. (`lib/admin_web/endpoint.ex`)
- **Serves the SPA:** the React client (builder, player, account, auth, analytics, home…) is built into `priv/static/client` at admin image build time, from `graasp/client` at `client-ref`, with `VITE_GRAASP_API_HOST` from the graasp-web GitHub environment. `ClientController` serves `index.html` for `/home`, `/account/*`, `/auth/*`, `/builder/*`, `/player/*`, `/analytics/*`… (`.github/workflows/deploy.yaml`, `lib/admin_web/router.ex`, `lib/admin_web/controllers/client_controller.ex`)
- **Calls core:** `backend_origin` is `https://<base_host>`, i.e. the public apex. Admin's calls to core (`Admin.Housekeeping`, `Admin.Publications.SearchIndex` reindex, with `ADMIN_SHARED_SECRET` Bearer) leave the VPC, come back in through the ALB and match rule 7. (`config/runtime.exs`, `lib/admin/housekeeping.ex`, `lib/admin/publications/search_index.ex`)
- No `/api` scope exists in admin's router today.

## Which client calls which host

| Client | Where it runs | API host it calls | Auth | Source |
|---|---|---|---|---|
| Client SPA, legacy query layer (`src/query`, axios, `withCredentials`) | `graasp.org` (served by admin) | `https://api.graasp.org/<route>`, **no `/api` prefix** (e.g. `/items/...`). Hits ALB rule 2 (rewrite) | session cookie | `client/src/config/env.ts`, `client/src/query/**/api.ts`, `gh variable list -R graasp/graasp-web -e production` |
| Client SPA, generated OpenAPI client (`src/openapi`) | same | **same origin**, `baseUrl: ''`, paths `/api/...`. Hits rule 7 | session cookie | `client/src/openapi/clientConfig.ts` |
| Client SPA websockets | same | `wss://api.graasp.org/ws` (core realtime) and `wss://api.graasp.org/items/pages/:id/ws[/read]` (Yjs pages). Both rewritten by rule 2 to `/api/...` | session cookie | `client/src/config/queryClient.ts`, `client/src/components/page/useYjs.ts` |
| Apps (iframes) | `apps.graasp.org` (CloudFront/S3) or third-party publisher origins | the `apiHost` handed over by the client context, i.e. `https://api.graasp.org` without `/api` (e.g. `/app-items/...`) | Bearer app JWT obtained by the client via `/app-items/:id/api-access-token` | `client/src/modules/builder/components/item/ItemContent.tsx`, `modules/player/item/Item.tsx`, `graasp-apps-query-client/src/api/*.ts` |
| Library (TanStack Start SSR, not Next.js any more) | `library.graasp.org` (ECS behind the ALB) | `VITE_API_HOST` = `https://api.graasp.org`, from both the SSR server and the browser, `credentials: 'include'` | session cookie (browser) | `library/src/config/env.ts`, `library/src/openapi/clientConfig.ts`, infra `libraryDefinition` env |
| Mobile builder (Expo) | native | default `https://api.graasp.org` (`EXPO_PUBLIC_API_HOST`). The repo looks dormant: builds date from 2023 and eas profiles still point at the removed `stage` env | not verified | `graasp-mobile-builder/src/config/env.ts`, `eas.json` |
| Short links | browser | `go.graasp.org/x` → 302 → `api.graasp.org/items/short-links/x` → rule 2 | none | `load_balancer.ts` |
| Admin itself | ECS | `https://graasp.org/api/...` via the public ALB | shared-secret Bearer | see Admin above |
| H5P | browser | integration page loaded straight from the S3 bucket URL (`VITE_GRAASP_H5P_INTEGRATION_URL`), no API traffic | n/a | GitHub env vars |

The client's own `deploy.yml` (S3 bucket `graasp-prod-client` plus a CloudFront distribution with comment `client`) still exists. Neither the bucket nor the distribution is defined in `graasp-infrastructure`, and every client route on the apex is served by admin (rule 8), so this looks like a leftover. Not verified against the AWS console.

## What has to change for all API traffic to go through admin

1. **Apex `/api/*` (rule 7) is the easy seam.** Delete rule 7 and apex `/api/*` falls through to admin (rule 8), where an admin proxy forwards to core. This covers the OpenAPI half of the SPA.
2. **`api.<env>` (rules 1 and 2) has to be retargeted to admin.** This covers the legacy SPA layer, the websockets, apps, the library and mobile. The host has to stay forever (mobile, third-party apps, short links), and so does the no-prefix rewrite. Retarget both rules to admin's target group and keep the `/api/$1` rewrite at the ALB, so admin only ever sees `/api/...`. Admin also has to accept `Host: api.<env>`: Phoenix does not reject requests by host, but anything that builds URLs from `@endpoint.url` or checks origin has to tolerate it.
3. **Admin needs a private path to core before rule 7 goes away.** Otherwise `backend_origin` (the public apex) would loop back into admin. Expose core in the Service Connect namespace (e.g. `core:<BACKEND_PORT>`), allow admin's security group in core's ingress, and point both the proxy and `backend_origin` at it.
4. **Websockets.** `/api/ws` and `/api/items/pages/:id/ws[/read]` are long-lived upgrades. Either the proxy tunnels websocket upgrades to core, or a higher-priority ALB rule keeps those paths on core during the transition. This depends on the websocket-strategy ticket.
5. **CORS.** Simplest is a transparent proxy that forwards preflight `OPTIONS` and core's `Access-Control-*` response headers unchanged. If admin answers CORS itself for ported routes, it has to reproduce core's rules exactly: the regex, credentials, the max-age and method list, and the per-route-group scope, including the dynamic app-publisher origins on app routes.
6. **Cookies.** Pass `Set-Cookie` through untouched. Because core's `session` cookie is on `.graasp.org`, admin already receives it on every apex request today, which is relevant to the "admin recognises core's session" ticket. Admin's own `_admin_key` is host-only on the apex. On `api.<env>` it would not be sent, and it must not clash.
7. **Headers core depends on.** Forward `X-Forwarded-For` **without appending** admin's peer address, because core takes the last entry as the client IP for actions and geolocation. Also forward `Origin` (action view, CORS), `Authorization` (app JWT, shared secret), `Cookie` and `Host`/`X-Forwarded-Proto`.
8. **Limits.** The ALB 60 s idle timeout already applies end to end. The proxy must stream request and response bodies (file uploads, exports, downloads) rather than go through `Plug.Parsers` limits, and must not add a shorter timeout than the ALB's.
9. **Maintenance mode.** Admin's rule deliberately skips the maintenance header condition while admin is active. Once admin fronts the API, maintenance gating for API traffic has to move into admin, or the rule must keep the header condition for `/api/*`.
10. **Capacity.** Admin runs 1 task at 512 CPU / 1024 MB in prod, against core's 2 tasks at 1024 / 2048 (`config.ts`). As the single entry point it needs autoscaling and a non-spot base. It currently has neither an autoscaling policy nor a desired count above 1.
11. **No client change is strictly required** if steps 1 and 2 are done at the ALB. Converging the SPA on the same-origin `/api` paths (as the OpenAPI layer already does) would let the SPA stop depending on `api.<env>`, but apps, the library and mobile still need it.

## Open points not verified here

- Actual ALB attributes and DNS records in the AWS console (drift from IaC), and whether the legacy `client` CloudFront distribution and bucket still exist.
- Whether the mobile app is still published and in use.
- Library production GitHub variables were not readable with `gh variable list` (likely a different environment name). The runtime value comes from the infra task definition anyway.
