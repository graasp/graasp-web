# Public folder export lives in Elixir

Visitors of a Public Folder can download it as a zip. We build this export in the Phoenix app (Oban job, streamed to S3, progress over PubSub in a LiveView) instead of calling the Node backend's BullMQ exporter.

The Node exporter emails a link to a logged-in member, so it has no way to report progress to a Visitor. Adding an unauthenticated progress API to Node would still leave the realtime page to build in Elixir. We chose to own the whole flow in one place.

## Consequences

- There are two exporters to keep in sync until the Node one is retired. The zip layout must stay compatible with Node's raw export (same file names, `.description.html` files, link files), and the visibility rules (public tag per item, hidden items hide their descendants, recycled and shortcut items skipped) must match Node's behavior.
- Etherpad items are skipped for now, as there is no etherpad client in Elixir.
- Follow-up: move the logged-in exports to the Elixir exporter so only one implementation remains.
