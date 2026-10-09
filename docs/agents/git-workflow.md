# Git workflow

`main` receives work only through merged pull requests.

1. Before editing any file, create a branch from up-to-date `main`, named after the ticket: `<ticket-number>-<short-slug>` (e.g. `281-chatbot-pdf`). Tickets live in GitHub Issues, see `issue-tracker.md`.
2. Commit all work to that branch.
3. When the work is done, ask the user whether to push the branch and open a pull request. Push and open it only after they say yes.

Already on `main` when asked to implement? Create the ticket branch first, then start.
