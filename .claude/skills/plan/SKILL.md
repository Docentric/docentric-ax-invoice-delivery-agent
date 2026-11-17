---
name: plan
description: Write an implementation plan for a GitHub issue to docs/plans/ and ask the user to approve it. Use before implementing a non-trivial change. Does not change code.
argument-hint: "[issue number]"
---
Plan the GitHub issue given as the argument (infer it from the branch name if missing).

1. Read the issue and its comments with the GitHub MCP tools. Inspect the affected metadata, X++ code and `SKILL.md`.
2. Write `docs/plans/<branch-name>.md` with:
   - Goal and acceptance criteria.
   - Affected elements, with new names that follow "X++ Conventions" in `AGENTS.md`.
   - Approach: CoC or event handler, and why. Security, labels, `SKILL.md` and `README.md` impact.
   - Verification: build with BP checks and manual steps in D365FO.
   - Open questions and risks.
3. Ask the user to approve or change the plan.

Do not change code. Do not commit the plan.
