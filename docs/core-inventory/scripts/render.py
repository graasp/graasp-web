"""Render routes.json (from trace-effects.ts) into ROUTES.md and INDEX.md.

Usage: python3 render.py <inventory-dir> <core-commit-sha>
"""

import collections
import json
import re
import sys
from pathlib import Path

out_dir = Path(sys.argv[1])
sha = sys.argv[2]
REPO = "https://github.com/graasp/graasp"

routes = [r for r in json.loads((out_dir / "routes.json").read_text()) if r.get("source")]

# auth mechanisms that dump-routes.ts cannot see because they are inline in the route
AUTH_OVERRIDES = {
    ("GET", "/api/auth"): "magic link token",
    ("GET", "/api/items/collections/search/rebuild"): "header secret `meilisearch-rebuild`",
    ("GET", "/api/items/pages/:id/ws/read"): "optional + item read check",
    ("GET", "/api/items/pages/:id/ws"): "session + validated + item write check",
}
AUTH_SHORT = {
    "isAuthenticated": "session",
    "optionalIsAuthenticated": "optional",
    "matchOne(validatedMember)": "validated",
    "matchOne(member)": "member",
    "matchOne(validatedMember|guest)": "validated or guest",
    "authenticateAppsJWT": "app JWT",
    "guestAuthenticateAppsJWT": "app JWT (guest ok)",
    "authenticatePassword": "password",
    "authenticatePasswordReset": "password reset token",
    "authenticateEmailChange": "email change token",
    "authenticateAdminSharedSecret": "admin shared secret",
}


def auth(r):
    key = (r["method"], r["url"])
    if key in AUTH_OVERRIDES:
        return AUTH_OVERRIDES[key]
    parts = [AUTH_SHORT.get(p, p) for p in r["preHandler"]]
    return " + ".join(parts) or "**none**"


def module(r):
    s = re.sub(r":\d+$", "", r["source"])
    if s.endswith("plugins/meta.ts"):
        return "meta"
    s = s.replace("src/services/", "").replace("/plugins/", "/")
    return s.rsplit("/", 1)[0] if "/" in s else s


def src_link(r):
    file, line = r["source"].rsplit(":", 1)
    return f"[{file.split('/')[-1]}:{line}]({REPO}/blob/{sha}/{file}#L{line})"


def ws_short(s):
    return s.replace("Topic ←", " ←")


def effects(r):
    out = []
    if r.get("websockets"):
        out.append("ws: " + ", ".join(ws_short(w) for w in r["websockets"]))
    if r.get("emails"):
        out.append("email: " + ", ".join(e.split(".")[-1] for e in r["emails"]))
    if r.get("jobs"):
        out.append("job: " + ", ".join(j.split(".")[-1] for j in r["jobs"]))
    if r.get("storage"):
        out.append("storage: " + ", ".join(sorted({s.split(":")[-1] for s in r["storage"]})))
    if r.get("search"):
        kinds = sorted({s.split(":")[0] for s in r["search"]})
        out.append("search: " + "/".join(kinds))
    if r.get("external"):
        out.append("external: " + ", ".join(sorted({e.split(":")[0] for e in r["external"]})))
    return "<br>".join(out)


def cell(xs, limit=None):
    xs = list(xs or [])
    if limit and len(xs) > limit:
        return ", ".join(f"`{x}`" for x in xs[:limit]) + f" +{len(xs) - limit}"
    return ", ".join(f"`{x}`" for x in xs)


by_mod = collections.defaultdict(list)
for r in routes:
    by_mod[module(r)].append(r)

header = [
    f"Generated from core at [`{sha[:9]}`]({REPO}/tree/{sha}) by `scripts/regenerate.sh`. Do not edit by hand.",
    "",
]

# ---------------------------------------------------------------- ROUTES.md
lines = ["# Core routes", "", *header]
lines += [
    f"{len(routes)} routes in {len(by_mod)} modules. Swagger UI and the DEV-only queue dashboard are left out.",
    "",
    "**Auth:** `session` = session cookie required · `optional` = session used if present · "
    "`validated` = member with a validated email · `member` = a member, not a guest · "
    "`guest` = item-login guest · `app JWT` = token given to an app iframe · **none** = no check.",
    "",
    "**Reads** leaves out tables the route also writes. Almost every item route reads `account`, `item`, "
    "`item_membership` and `item_visibility` for the permission check.",
    "",
    "**Calls** are the service methods the handler calls directly, a starting point for the spec. "
    "**Hooks** are service hooks fired along the way that have handlers registered.",
    "",
    "## Summary",
    "",
    "| Module | Routes | No auth | Writes DB | WS | Email | Job | Storage | Search | External |",
    "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
]
for m in sorted(by_mod):
    rs = by_mod[m]
    n = lambda f: sum(bool(r.get(f)) for r in rs) or ""  # noqa: E731
    lines.append(
        f"| [{m}](#{re.sub(r'[^a-z0-9-]', '', m.replace('/', '').lower())}) | {len(rs)} "
        f"| {sum(auth(r) == '**none**' for r in rs) or ''} | {n('tablesWritten')} | {n('websockets')} "
        f"| {n('emails')} | {n('jobs')} | {n('storage')} | {n('search')} | {n('external')} |"
    )

for m in sorted(by_mod):
    lines += [
        "",
        f"## {m}",
        "",
        "| Route | Auth | Writes | Reads | Side effects | Calls / hooks |",
        "|---|---|---|---|---|---|",
    ]
    for r in by_mod[m]:
        ws = " (websocket)" if r["websocket"] else ""
        calls = "<br>".join([*(f"`{c}`" for c in r.get("entrypoints", [])),
                             *(f"hook `{h}`" for h in r.get("hooks", []))])
        lines.append(
            f"| `{r['method']} {r['url']}`{ws}<br>{src_link(r)} | {auth(r)} "
            f"| {cell(r.get('tablesWritten'))} | {cell(r.get('tablesRead'), 6)} | {effects(r)} | {calls} |"
        )
(out_dir / "ROUTES.md").write_text("\n".join(lines) + "\n")

# ---------------------------------------------------------------- INDEX.md
def route_ref(r):
    return f"`{r['method']} {r['url']}`"


def index_section(title, key, label=lambda v: v, intro=None):
    idx = collections.defaultdict(list)
    for r in routes:
        for v in r.get(key, []):
            idx[label(v)].append(r)
    sec = ["", f"## {title}", ""]
    if intro:
        sec += [intro, ""]
    if not idx:
        return sec + ["None found.", ""]
    sec += ["| | Routes |", "|---|---|"]
    for k in sorted(idx):
        uniq = {route_ref(r): None for r in idx[k]}
        sec.append(f"| `{k}` | {'<br>'.join(uniq)} |")
    return sec


lines = ["# Core side-effect index", "", *header]
lines += ["Reverse view of [ROUTES.md](ROUTES.md): for each table or side effect, the routes that reach it."]

# tables: writers and readers
writers, readers = collections.defaultdict(list), collections.defaultdict(list)
for r in routes:
    for t in r.get("tablesWritten", []):
        writers[t].append(r)
    for t in r.get("tablesRead", []):
        readers[t].append(r)
lines += [
    "",
    "## Tables",
    "",
    "Written by: the routes that insert, update or delete rows. Read by: route count only, since the "
    "permission tables are read almost everywhere.",
    "",
    "| Table | Written by | Read by |",
    "|---|---|---:|",
]
for t in sorted(set(writers) | set(readers)):
    w = "<br>".join({route_ref(r): None for r in writers[t]}) or "—"
    lines.append(f"| `{t}` | {w} | {len(readers[t])} |")

lines += index_section("Websocket publications", "websockets", intro="Topic ← event, as published by the route.")
lines += index_section("Emails", "emails", intro="The function that triggers the email.")
lines += index_section("Background jobs", "jobs")
lines += index_section("File storage", "storage")
lines += index_section("Search index", "search", intro="`write` updates the Meilisearch index, `query` searches it.")
lines += index_section("External services", "external")
lines += index_section("Service hooks", "hooks", intro="`Service:phase:event` hooks fired, with handlers registered in another module.")
(out_dir / "INDEX.md").write_text("\n".join(lines) + "\n")

print(f"rendered {len(routes)} routes, {len(by_mod)} modules", file=sys.stderr)
