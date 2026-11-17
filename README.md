[![Docentric AX](https://img.shields.io/badge/DOCENTRIC-AX-E68800?style=for-the-badge&labelColor=002050)](https://ax.docentric.com/)
[![Dynamics 365 F&O](https://img.shields.io/badge/Dynamics%20365%20F%26O-002050?style=for-the-badge&logo=microsoftdynamics365&logoColor=white)](https://learn.microsoft.com/en-us/dynamics365/fin-ops-core/fin-ops/)
[![Work IQ](https://img.shields.io/badge/WORK-IQ-742774?style=for-the-badge&logo=microsoft&logoColor=white&labelColor=002050)](https://learn.microsoft.com/en-us/microsoft-365/copilot/extensibility/work-iq)
[![D365FO MCP](https://img.shields.io/badge/D365FO-MCP-008080?style=for-the-badge&labelColor=002050)](https://learn.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/copilot/copilot-mcp)
[![D365FO Business Skills](https://img.shields.io/badge/D365FO-Business%20Skills-0078D4?style=for-the-badge&labelColor=002050)](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/data-platform-business-skills)
[![X++](https://img.shields.io/badge/X%2B%2B-1E3A8A?style=for-the-badge&logo=codemagic&logoColor=white)](https://learn.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/dev-ref/xpp-language-reference)
[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://learn.microsoft.com/en-us/powershell/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

# Invoice Delivery Agent

Finding out why an invoice was not delivered can take hours. Finance teams need to check Print Management settings, email logs, and customer details. Built on Docentric AX Free Edition, the Invoice Delivery Agent helps find delivery problems and explains what went wrong in simple terms. It can also suggest how to fix the problem and, with the user's approval, take action, such as correcting email addresses or resending invoices. It can even check for missing customer email addresses before invoices are sent, helping prevent delivery problems.

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
- [Docentric Invoice Delivery Agent](https://ax.docentric.com/exploring-ai-powered-invoice-troubleshooting-in-d365fo-with-docentric-and-business-skills)

## Prerequisites

[Docentric AX Free Edition](https://ax.docentric.com/free-edition/) v3.6.0 or later is required.

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

- `Metadata`: *Folder containing the D365FO model (`DocentricBulkUploadShowcase`, model name `Docentric AX Bulk Upload Control Showcase`)*
- `Projects`: *Folder containing Visual Studio files (e.g., solutions, projects gluing the D365FO model artifacts).*
- `AOS_CreateMetadataSymbolicLinks.ps1`: *Script to create the symbolic links to the AosService\PackagesLocalDirectory folder.*
- `AOS_RemoveMetadataSymbolicLinks.ps1`: *Script to remove the symbolic links from the AosService\PackagesLocalDirectory folder.*
- `.gitattributes`: *Defines project-based rules for manipulating files and paths attributes when a Git action is performed (e.g., line-endings, file compare, etc.).*
- `.gitignore`: *Defines project-based rules for ignoring files and folders in the Git repository.*

## License

This software is licensed under the **MIT License**. In short: you may use, copy, modify, merge, publish, distribute, sublicense and sell copies of it free of charge, as long as the copyright notice and the permission notice stay in all copies. The software is provided "as is", without warranty of any kind, and the authors are not liable for any claim or damage that arises from it. The full text is in the [LICENSE](LICENSE) file.
