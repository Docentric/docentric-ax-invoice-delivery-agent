---
name: implement
description: Implement a GitHub issue on the current branch without committing. Use when the branch already exists.
argument-hint: "[issue number]"
disable-model-invocation: true
---
Implement the GitHub issue given as the argument (infer it from the branch name if missing) on the current branch.

1. Read the issue with the GitHub MCP tools and the plan in `docs/plans/<branch-name>.md` if it exists.
2. Implement the change following `AGENTS.md`. Update `SKILL.md` and `README.md` when behavior changes.
3. Build as described in "Build and Verify" in `AGENTS.md` and fix all errors and new warnings.
4. Summarize the changes and the manual verification steps, then ask the user whether the implementation is done as expected.

Do not commit, push or open a PR. Never work on `main`.
