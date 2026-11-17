[![Docentric AX](https://img.shields.io/badge/DOCENTRIC-AX-E68800?style=for-the-badge&labelColor=002050)](https://ax.docentric.com/)
[![Dynamics 365 F&O](https://img.shields.io/badge/Dynamics%20365%20F%26O-002050?style=for-the-badge&logo=microsoftdynamics365&logoColor=white)](https://learn.microsoft.com/en-us/dynamics365/fin-ops-core/fin-ops/)
[![Work IQ](https://img.shields.io/badge/WORK-IQ-742774?style=for-the-badge&logo=microsoft&logoColor=white&labelColor=002050)](https://learn.microsoft.com/en-us/microsoft-365/copilot/extensibility/work-iq)
[![D365FO MCP](https://img.shields.io/badge/D365FO-MCP-008080?style=for-the-badge&labelColor=002050)](https://learn.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/copilot/copilot-mcp)
[![D365FO Business Skills](https://img.shields.io/badge/D365FO-Business%20Skills-0078D4?style=for-the-badge&labelColor=002050)](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/data-platform-business-skills)
[![X++](https://img.shields.io/badge/X%2B%2B-1E3A8A?style=for-the-badge&logo=codemagic&logoColor=white)](https://learn.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/dev-ref/xpp-language-reference)
[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://learn.microsoft.com/en-us/powershell/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

# Docentric Invoice Delivery Agent

*"We never got those invoices."* One short reply from a customer, and someone on your finance team needs to find out what happened. Were the invoices sent? Did they go to the correct address? What went wrong, and how can it be fixed?

The Docentric Invoice Delivery Agent investigates invoice delivery problems in Dynamics 365 Finance and Operations (D365FO), explains what it finds, and suggests corrective actions, such as resending invoices to the correct address or updating the customer's invoice email address. The user stays in control: the agent asks for a decision before it changes anything.

The agent is built with [Microsoft Business Skills](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/data-platform-business-skills), the [Dynamics 365 ERP MCP server](https://learn.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/copilot/copilot-mcp), and [Docentric AX Free Edition](https://ax.docentric.com/free-edition/). It was built during Microsoft's [Dynamics 365 ERP in Work IQ](https://aka.ms/ERPWorkIQ) private preview.

## What the agent does

Ask it, for example, *"Check why the invoices in this email were not sent."* The agent reads the customer's email (or an attached collection letter), identifies the invoices, and then:

1. **Investigates invoice delivery problems.** It looks up sales, free-text, and project invoices and checks the outgoing email queue (**Batch email sending status**): recipients, sending statuses, and email information. When an invoice has no outgoing email record, it checks the Docentric **Print archive** for the print destination that was used. Findings are labelled *Confirmed*, *Likely*, or *Can't tell*.
2. **Corrects the recipient and resends.** The user chooses the address (the one requested in the email, the sender's address, or another one). The agent duplicates the existing email record, updates the recipient, and restarts sending. The original record stays unchanged, so the sending history is preserved.
3. **Updates the customer's invoice email address.** With the user's approval, it adds or updates the customer's email address with the *Invoice* purpose, so future invoices go to the right address.
4. **Prepares a reply to the customer.** It can create a draft reply (or send it) summarizing which invoices were resent and to which address.

> NOTE: An email with status *Sent* has left the system. That doesn't confirm that it reached the customer's inbox.

## What's in this repository

| Component | Description |
|---|---|
| Business Skill `DocAgentEmailInvestigationSkill` ([SKILL.md](Metadata/DocInvoiceDeliveryAgent/DocInvoiceDeliveryAgent/AxSkill/DocAgentEmailInvestigationSkill/SKILL.md)) | One Business Skill covering the whole workflow: investigation, recipient correction and resending, customer email update, and the customer reply. |
| X++ extension `SysOutgoingEmailTableForm_DIDA_Extension` | Adds a **Message > Duplicate** button to the **Batch email sending status** form (`SysOutgoingEmailTable`). It copies the selected email in the *Expired* status, so the copy can be changed with **Message > Update message** and queued again with **Restart send**. Emails that were already *Sent* can't be updated directly. |

No Custom AI Tools are needed. The agent uses the existing D365FO and Docentric functionality exposed by the ERP MCP server (Data Tools and Form Tools), such as the `SalesInvoiceHeadersV4`, `FreeTextInvoiceHeaders`, `CustomerElectronicAddresses`, and `DocPrintJobHeaders` data entities and the `SysOutgoingEmailTable` form. The agent works within the user's D365FO security permissions.

## Docentric AX

[Docentric AX](https://ax.docentric.com) is a complete reporting and output management solution for Microsoft Dynamics 365 Finance and Operations. The solution provides companies and partners with a better way to create reports and automate the distribution and archiving of business documents.

Two editions of the solution are available:

- Docentric AX Free Edition: Solves most common shortcomings in D365FO output management.
- Docentric AX Full Edition: Report design and advanced output management features.

A complete feature list with a comparison to standard D365FO solutions and what’s part of the Free and Full Edition is described here: https://ax.docentric.com/feature-list.

## Download

Each release contains the source archives and the model file for import with ModelUtil.
[Releases](../../releases)

## Articles

You can learn more about the solution here:
- [Docentric Invoice Delivery Agent](https://ax.docentric.com/exploring-ai-powered-invoice-troubleshooting-in-d365fo-with-docentric-and-business-skills/)

Related articles:
- [How Microsoft Business Skills and the Dynamics 365 ERP MCP Server Work Together](https://ax.docentric.com/how-microsoft-business-skills-and-the-dynamics-365-erp-mcp-server-work-together/)
- [Docentric's Experience with Microsoft Business Skills and Dynamics 365 ERP MCP Server](https://ax.docentric.com/docentrics-experience-with-microsoft-business-skills-and-dynamics-365-erp-mcp-server/)
- [Microsoft's Dynamics 365 ERP in Work IQ announcement](https://aka.ms/ERPWorkIQ)

## Prerequisites

- [Docentric AX Free Edition](https://ax.docentric.com/free-edition/) v3.6.0 or later.
- A D365FO environment with Business Skills and the Dynamics 365 ERP MCP server enabled.
- An MCP-compatible agent connected to the ERP MCP server (for example, Microsoft 365 Copilot, Copilot Studio, or Microsoft Foundry). To read customer emails and create replies, the agent also needs mail tools (for example, Outlook).
- The **Docentric Email distributor** batch job running, so that the emails the agent queues are actually sent.

## Using the Business Skill

The skill is included in the model as an AOT artifact (`AxSkill`), so it's deployed together with the model. If your environment doesn't support built-in (AOT) skills yet, create a custom skill in **System administration > Setup > Business skills** and upload [SKILL.md](Metadata/DocInvoiceDeliveryAgent/DocInvoiceDeliveryAgent/AxSkill/DocAgentEmailInvestigationSkill/SKILL.md).

The **Message > Duplicate** button comes from the X++ extension in this model, so the model must be deployed to the environment either way.

> NOTE: Business Skills guide the agent, but they can't enforce its behavior. Approvals, permissions, and validations are enforced by D365FO security and application logic.

## Instructions

The X++ metadata in the repository is under the Metadata folder, which contains all the objects needed. We need to make the model visible to D365FO (at **:\AOSService\PackagesLocalDirectory**) by creating [Symbolic links](https://en.wikipedia.org/wiki/NTFS_links) to the model folder on the filesystem.

> Using the described approach you can use multiple Git repositories (e.g., solutions or customizations) on the same D365FO OneBox environment.

To do so, follow the next instructions (before you start, make sure you have Visual Studio closed):

1. **Add the model to D365FO.** Run the following command in PowerShell as an Administrator. It creates a symbolic link in **:\AOSService\PackagesLocalDirectory** for the model folder of this repository (a model that is already there is skipped):

`.\AOS_CreateMetadataSymbolicLinks.ps1`

2. **Remove the model from D365FO when you no longer need it.** Run the following command in PowerShell as an Administrator. It deletes the symbolic link from **:\AOSService\PackagesLocalDirectory** and leaves the repository itself untouched:

`.\AOS_RemoveMetadataSymbolicLinks.ps1`

> NOTE: Delete only symbolic links, not the source folders!

### Using scripts with Unified Development Environment (UDE)
Both scripts detect the D365FO package's local folder, but with UDE environments, you have a custom metadata folder, which is set through the `'Visual Studio > Dynamics 365 Extension > Configure Metadata'` in setting `'Folder for your own custom metadata'`. To create a symbolic link, use `.\AOS_CreateMetadataSymbolicLinks.ps1 -PackagesLocalFolder "C:\CustomAOS\PackagesLocalDirectory"`.

> NOTE: To remove use the same parameter with script `.\AOS_RemoveMetadataSymbolicLinks.ps1 -PackagesLocalFolder "C:\CustomAOS\PackagesLocalDirectory"`.

## Folder structure

The repository starts with the following folder structure:

- `Metadata`: *Folder containing the D365FO model (`DocInvoiceDeliveryAgent`, model name `Docentric AX Invoice Delivery Agent`)*
- `Projects`: *Folder containing Visual Studio files (e.g., solutions, projects gluing the D365FO model artifacts).*
- `AOS_CreateMetadataSymbolicLinks.ps1`: *Script to create the symbolic links to the AosService\PackagesLocalDirectory folder.*
- `AOS_RemoveMetadataSymbolicLinks.ps1`: *Script to remove the symbolic links from the AosService\PackagesLocalDirectory folder.*
- `.gitattributes`: *Defines project-based rules for manipulating files and paths attributes when a Git action is performed (e.g., line-endings, file compare, etc.).*
- `.gitignore`: *Defines project-based rules for ignoring files and folders in the Git repository.*
- `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`: *Instructions for AI coding agents (GitHub Copilot, Claude Code), including the code review checklist.*
- `.claude/skills`: *Development workflow skills for the agents: `create-branch`, `plan`, `implement`, `create-pull-request`, `code-review`.*
- `.mcp.json`: *GitHub MCP server for Claude Code (needs the `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable). Visual Studio uses `Projects/DocInvoiceDeliveryAgent/.mcp.json` and signs in with your GitHub account.*

## License

This software is licensed under the **MIT License**. In short: you may use, copy, modify, merge, publish, distribute, sublicense and sell copies of it free of charge, as long as the copyright notice and the permission notice stay in all copies. The software is provided "as is", without warranty of any kind, and the authors are not liable for any claim or damage that arises from it. The full text is in the [LICENSE](LICENSE) file.
