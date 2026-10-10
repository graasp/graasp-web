# Investigating Sentry issues

Sentry tickets arrive as a URL or a short ID (`ADMIN-3F`). Investigate them with the locally installed `sentry-cli` (v3), plus `curl` against the Sentry REST API for the one thing the CLI cannot show: an event's stack trace.

## Setup

`sentry-cli info` must list the `event:read` and `project:read` scopes. An org token (`org:ci` only) can upload releases but gets a 403 on every read below. If the scopes are missing, ask the user to create a personal token at `https://graasp.sentry.io/settings/account/api/auth-tokens/` and run `! sentry-cli login --auth-token <token>`; it stores the token in `~/.sentryclirc`. Shell state does not persist between commands, so prefix every `curl` below with:

```sh
TOKEN=${SENTRY_AUTH_TOKEN:-$(awk -F= '/^token/{print $2}' ~/.sentryclirc)}
```

Our org is hosted in the US region; `https://sentry.io/api/0/` routes there.

## URL → command map

Take `<org>` from the URL host (`<org>.sentry.io`) or the `/organizations/<org>/` segment. Take `<project>` from the `?project=<id>` query param; `-p` accepts the numeric ID.

| URL shape | Command |
| --- | --- |
| `/issues/?project=<p>&query=<q>&environment=<e>` | `sentry-cli issues list -o <org> -p <p> --query "<q> environment:<e>"` |
| `/issues/<issue_id>/` | `curl -sH "Authorization: Bearer $TOKEN" https://sentry.io/api/0/organizations/<org>/issues/<issue_id>/` |
| `/issues/<issue_id>/events/<event_id>/` (also `latest`, `oldest`, `recommended`) | `curl -sH "Authorization: Bearer $TOKEN" https://sentry.io/api/0/organizations/<org>/issues/<issue_id>/events/<event_id>/` |
| `/issues/<issue_id>/events/` | `sentry-cli events list -o <org> -p <p> -T -U` (all project events; narrow with the issue's API `events/` endpoint if needed) |
| Short ID `ADMIN-3F` (no URL) | `curl … https://sentry.io/api/0/organizations/<org>/shortids/ADMIN-3F/` → `.groupId` is the `<issue_id>` |
| `/explore/logs/?query=<q>` | `sentry-cli logs list -o <org> -p <p> --query "<q>"` (beta) |

Legacy `https://sentry.io/organizations/<org>/issues/<issue_id>/…` URLs map the same way.

Extract the crash site from an event, innermost frame first. Our events carry `inApp: false` on every frame, so mark ours by path instead: `lib/admin` frames are our code, other `lib/` frames are dependencies.

```sh
curl -sH "Authorization: Bearer $TOKEN" <event-url> | jq '{
  release, environment: (.tags[] | select(.key=="environment") | .value),
  exceptions: [.entries[] | select(.type=="exception") | .data.values[] | {
    type, value,
    frames: [.stacktrace.frames | reverse[] | "\(if (.filename | startswith("lib/admin")) then "*" else " " end) \(.filename):\(.lineNo) \(.function)"]
  }]
}'
```

## Investigation

1. **Fetch the issue**: title, `count`, `firstSeen`/`lastSeen`, `firstRelease`/`lastRelease`.
2. **Fetch the `recommended` event** and extract its exception, `lib/admin` frames, `release`, and `environment` (`production`, `staging`, `development`; see `config/runtime.exs`). Breadcrumbs (`.entries[] | select(.type=="breadcrumbs")`) show what ran just before.
3. **Read the code as deployed.** `release` is the `mix.exs` version; tags are `v<release>`. Frame paths are relative to the repo root, so read them with `git show v<release>:<filename>`, then diff against `main` to learn whether the fault is already fixed.
4. **Write the finding**: the root cause pinned to a file and line at the deployed release, or the exact data the events lack to pin it. That pin is the step's completion criterion.

Reproducing or fixing the bug continues in `/diagnosing-bugs`. Resolving or muting the issue in Sentry (`sentry-cli issues resolve -i <issue_id>`) is outward-facing: run it only when the user asks.
