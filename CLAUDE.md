@AGENTS.md

## Claude Code Notes

- Code review checklist: `.github/copilot-instructions.md` (section "Code Review").
- Skills are in `.claude/skills/`. The GitHub MCP server is configured in `.mcp.json` and needs the `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable.
- On the D365FO development environment, build with `.\_Scripts\AOS_BuildModel.ps1` and read the logs in `artifacts\Build`. On another machine, you cannot build X++. Ask the user to build in Visual Studio and share the Error List.
