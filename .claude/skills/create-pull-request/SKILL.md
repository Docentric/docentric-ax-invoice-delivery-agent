---
name: create-pull-request
description: Commit, push and open a pull request for the current branch after the user has confirmed the implementation. Use when the work is done and reviewed.
argument-hint: "[issue number]"
disable-model-invocation: true
---
Open a pull request for the current branch (issue number given as the argument; infer it from the branch name if missing).

1. Confirm with the user that the implementation is done and reviewed, and that the build passes. Skip the question if the user already confirmed in this session.
2. Commit as described in "Commits and Pull Requests" in `AGENTS.md` and push the branch (never `main`). Do not commit `docs/plans/`.
3. Open a PR to `main` with the GitHub MCP tools. Title like the commit. Body from `.github/pull_request_template.md` with every section filled in.
4. Report the PR link.
