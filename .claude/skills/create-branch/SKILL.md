---
name: create-branch
description: Read a GitHub issue, then create and check out a branch named by repository convention. Use when starting work on an issue. Does not implement anything.
argument-hint: "[issue number]"
disable-model-invocation: true
---
Prepare a branch for the GitHub issue given as the argument (ask for the number if missing).

1. Read the issue with the GitHub MCP tools. Check for existing branches and PRs for it; stop and report if one exists.
2. Create the branch from the latest `main` with the GitHub MCP tools, named as in "Branching and Versioning" in `AGENTS.md`.
3. Run `git fetch` and check out the branch locally.

Do not implement anything. Never work on `main`.
