---
name: code-review
description: Review local changes, or a GitHub pull request when a PR number is given, with the Code Review checklist. Reports findings and does not submit a review unless asked.
argument-hint: "[PR number, optional]"
---
Review with the "Code Review" checklist in `.github/copilot-instructions.md`.

- With a PR number: read the PR, its diff, files and existing review comments with the GitHub MCP tools.
- Without a PR number: review the uncommitted and unpushed changes on the current branch (diff against `main`).

Output:
1. Short summary of the change.
2. Findings grouped as Blocking / Suggestions / Nits, each with file, line and a concrete fix.
3. Missing build evidence, manual verification or docs.
4. Recommendation: approve, comment or request changes.

Fix local findings only when the user approves. Do not submit a PR review unless asked.
