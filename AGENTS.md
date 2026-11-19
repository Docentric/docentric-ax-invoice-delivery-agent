# Agent Instructions: Docentric Invoice Delivery Agent

Shared instructions for all AI coding agents (GitHub Copilot, Claude Code). This file is the single source of truth. `CLAUDE.md` and `.github/copilot-instructions.md` only point here.

D365FO X++ model that adds a Business Skill and a small form extension for the Docentric Invoice Delivery Agent. It depends on Docentric AX (Free Edition). See `README.md`.

## Repository Layout

| Path | Description |
|------|-------------|
| `Metadata/DocentricAXInvoiceDeliveryAgent` | Package and model `DocentricAXInvoiceDeliveryAgent` ("Docentric AX Invoice Delivery Agent POC"). References `ApplicationPlatform`, `ApplicationFoundation`, `DocentricAX`. |
| `Metadata/.../AxSkill/DocInvoiceEmailInvestigationSkill/SKILL.md` | Business Skill for the D365FO agent. This is product content, not an instruction for coding agents. |
| `Projects/DocentricAXInvoiceDeliveryAgent` | Visual Studio solution (`.slnx`) and D365FO project (`.rnrproj`). |
| `AOS_*MetadataSymbolicLinks.ps1` | Link the model into PackagesLocalDirectory (see README). |
| `_Scripts/` (`AOS_BuildModel.ps1`, `AOS_ExportModel.ps1`, `AOS_ExportDeployablePackage.ps1`, `PPAC_DeployPackage.ps1`, `PPAC_RemovePackage.ps1`, `AOS_Common.psm1`) | Build the model, export the model file, create the LCS and UDE deployable packages, deploy the UDE package to and remove the model from a Power Platform environment (see README). |
| `artifacts/` | Output of the build and export scripts. Not committed (`.gitignore`). |
| `.claude/skills/` | Development workflow skills, used by Copilot and Claude Code. |
| `docs/plans/` | Implementation plans. Not committed (`.gitignore`). |

## General Principles

- Keep changes small and focused. Follow existing patterns. No unrelated refactoring.
- Inspect existing code before you change it. Do not assume; verify or ask.
- Never invent X++ APIs, form control names, data entities or Docentric AX members. Verify them in metadata or documentation.
- Never commit secrets or personal data.
- Write chat answers, commits, PRs, comments and docs in ASD-STE100 Simplified Technical English: plain, specific and calm. No hype, no em or en dashes, no "It's not X, it's Y" phrasing.

## X++ Conventions

Project identifier: `DIDA`. Do not use the Docentric Core identifiers (`DC`, `DCE`, `DCX`, `DCL`, `DR`) for new elements. Keep established names; do not rename only to apply these rules.

| Element | Pattern |
|---------|---------|
| New model element (class, table, form, EDT, enum, menu item, security element, skill) | `Doc<MeaningfulName>_DIDA` (interfaces `IDoc...`) |
| Table or form extension | `<Table>.TableExtension_DIDA`, `<Form>.FormExtension_DIDA` |
| Other extension element | `<Element>.Extension_DIDA` |
| Augmentation class (`final`, `[ExtensionOf]`) | `<Table>[Table]_DIDA_Extension`, `<Form>[Form]_DIDA_Extension`, `<Class>_DIDA_Extension`. Add `Table`/`Form` only if the base name does not end with it. |
| Added field, field group, enum value, control, method, member | `<Name>_DIDA` |
| Event handler class | `<Table>Table_DIDA_EventHandler`, `<Form>Form_DIDA_EventHandler`, `<Class>_DIDA_EventHandler` |
| Event handler method / its delegation method in the augmentation class | `<Target>_On<Event>` / `<Target>_On<Event>_DIDA` |

- Use Chain of Command for table, class and form methods. CoC wrappers keep the base name and signature (no default values) and call `next`.
- Use event handlers for form data source, data field and control events, or where CoC is not possible. Put them in a separate handler class, and put the logic in the augmentation class.
- PascalCase for elements and constants, camelCase for methods and variables.
- Use labels for user-visible text. Add XML documentation (`<summary>`, `<param>`, `<returns>`) with useful content to classes and methods.
- Balance `ttsbegin`/`ttscommit`. Use `forupdate` only when you update. Use `firstonly` for single-record selects.
- Cover new menu items, buttons and operations with a privilege. Do not bypass the user's security.

Compiler and Best Practice (BP) warnings:

- Fix warnings first. Do not add new warnings.
- Suppress only when a fix is not suitable and the user approves. Add the suppression to `AxIgnoreDiagnosticList\DocentricAXInvoiceDeliveryAgent_BPSuppressions.xml` in the model folder with `DiagnosticType`, `Severity`, `Path`, `Moniker`, `Message` copied from build output and a specific `Justification`. Commit it with the related code.

Business Skill (`SKILL.md`):

- Keep form, control, data entity and field names in sync with the X++ code and Docentric AX.
- Keep the YAML front matter valid (spaces, no tabs). Increase `metadata.version` when the skill changes.

## Build and Verify

- Build the model `DocentricAXInvoiceDeliveryAgent` in Visual Studio with Best Practice checks on. Copilot in Visual Studio uses its build tool. On the D365FO development environment, you can also run `.\_Scripts\AOS_BuildModel.ps1` in a terminal. If you cannot build (for example, a terminal on another machine), ask the user to build and share the Error List.
- Build logs: `BuildModelResult.xml` and `BPCheck.xml` in `<PackagesLocalDirectory>\DocentricAXInvoiceDeliveryAgent\` (Visual Studio), or `Xppc.xml` and `BPCheck.xml` in `artifacts\Build\` (`_Scripts\AOS_BuildModel.ps1`).
- There are no automated tests. Describe manual verification in D365FO, and for `SKILL.md` changes, test the agent scenario through the ERP MCP server.
- Never claim that a build or test passed without evidence.

## Branching and Versioning

- `main` is always releasable. Never commit or push to `main`; all changes go through a pull request.
- One short-lived branch per GitHub issue, from the latest `main`: `<type>/<issue>_<short-kebab-description>`. Types: `feature`, `bugfix`, `hotfix`, `chore`, `docs`. Without an issue: `chore/noissue_<description>`.
- Keep the branch current by rebasing on or merging `main`. Delete it after merge.
- Releases use Git tags `v<MAJOR.MINOR.PATCH>` (optional prerelease suffix, for example `v1.2.0-preview.0`). The model descriptor (`Metadata/DocentricAXInvoiceDeliveryAgent/Descriptor/DocentricAXInvoiceDeliveryAgent.xml`) must match: `VersionMajor.VersionMinor.VersionBuild` = `MAJOR.MINOR.PATCH`, `VersionRevision` = `0`. Change it in the PR that prepares the release.
- Only maintainers create tags and releases. Do not create them unless asked.

## Commits and Pull Requests

- Commit message: `#<issue> <Imperative summary>` (capitalized, no trailing period, about 72 characters or less). Use `#noissue` when there is no issue. Add a body only when the reason is not obvious.
- End the commit message of AI-assisted commits with the trailer `Co-authored-by: Copilot` on its own line, after a blank line. Do not add an email address or other co-author trailers.
- One logical change per commit.
- PR targets `main`, title like the commit, body from `.github/pull_request_template.md` with every section filled in.
- Update `README.md` and `SKILL.md` when behavior changes.
- Prefer squash merge. Address review comments with follow-up commits; do not force-push reviewed history.

## GitHub Access

- Use the GitHub MCP server for all GitHub operations (issues, branches, pull requests, reviews). Fall back to the `gh` CLI only when MCP is unavailable. Use `git` for local commits and pushes.
- MCP configuration: `.mcp.json` (Claude Code, needs the `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable) and `Projects/DocentricAXInvoiceDeliveryAgent/.mcp.json` (Visual Studio, GitHub sign-in).
- Before you start, read the issue and check for existing branches and PRs.
- Do not put tokens in prompts, files or commits.

## Skills

Workflows in `.claude/skills/<name>/SKILL.md`. Invoke with `/<name>`. The skills reference this file and do not repeat its rules.

| Skill | Purpose |
|-------|---------|
| `create-branch` | Read the issue and create the branch |
| `plan` | Write an implementation plan to `docs/plans/` |
| `implement` | Implement the issue on the current branch |
| `create-pull-request` | Commit, push and open the PR |
| `code-review` | Review local changes or a PR with the checklist in `.github/copilot-instructions.md` |
