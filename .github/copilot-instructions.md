# Copilot Instructions

All project rules (layout, X++ conventions, build, branching, versioning, commits, pull requests, GitHub access) are in [`AGENTS.md`](../AGENTS.md). Follow them. Do not duplicate them here.

Workflows are skills in `.claude/skills/` (invoke with `/<name>`).

## Code Review

Applies to human and Copilot reviews. Review the diff against `AGENTS.md` and this checklist. Comment only on actionable findings, ordered by severity (security/correctness > extensibility > docs > style).

- **Scope:** one issue per PR, no unrelated refactoring. Branch, commit and PR title follow `AGENTS.md`.
- **Correctness:** balanced `ttsbegin`/`ttscommit`, exceptions handled outside the transaction, empty buffers checked, `forupdate` only when updating, `firstonly` for single records, set-based operations where possible.
- **Extensibility:** no overlayering. CoC for table, class and form methods (calls `next`, same signature without default values). Event handlers only for data source, field and control events or where CoC is not possible, in a separate `_DIDA_EventHandler` class.
- **Naming:** new elements and members follow the X++ Conventions table with identifier `DIDA`. Established names are not renamed without a reason.
- **Security:** new menu items, buttons and operations are covered by privileges. Writes respect the user's permissions. No secrets in code.
- **UI and docs:** labels for user-visible text. XML documentation with useful content. `README.md` updated when behavior changes.
- **Business Skill:** `SKILL.md` matches the X++ control names, data entities and fields. Valid YAML front matter. `metadata.version` increased.
- **Warnings:** no new compiler or BP warnings. Each suppression is approved, specific and justified.
- **Versioning:** in a release PR, the descriptor version matches the planned `v<MAJOR.MINOR.PATCH>` tag.
- **Verification:** the PR describes the build result and the manual test in D365FO.

Etiquette: prefix non-blocking remarks with `nit:`. Explain why and suggest a concrete fix. Do not approve while blocking comments are unresolved.
