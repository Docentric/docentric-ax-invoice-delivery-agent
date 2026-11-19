<#
	.SYNOPSIS
	Deploys the UDE unified package of the D365FO model DocentricAXInvoiceDeliveryAgent to a Power Platform environment.

	.DESCRIPTION
	*** Script version: PPAC_DeployPackage.ps1 v1.0 ***

	Deploys the unified package with 'pac package deploy' to a Power Platform environment with finance and operations apps
	(for example, a unified developer environment that you manage in the Power Platform admin center).

	Before the deployment, the script makes sure that the latest version of the Power Platform CLI (Windows MSI) is installed.
	If the CLI is not installed, the script installs it for the current user. If a newer version is available, the script installs it.
	If the Power Platform CLI has no auth profile, the script opens the sign-in.

	Create the package first with '.\_Scripts\AOS_ExportDeployablePackage.ps1'. By default, the script deploys
	'artifacts\DeployablePackage\DocentricAXInvoiceDeliveryAgent-<version>-UDE\TemplatePackage.dll'.
	The version is read from the model descriptor in the repository.
	The deployment log is written to 'artifacts\PPAC\Deploy'.

	.PARAMETER Environment
	The URL (for example https://contoso-dev.crm4.dynamics.com/) or the ID of the target Power Platform environment.

	.PARAMETER PackagePath
	The TemplatePackage.dll of the UDE unified package folder, or the UDE unified package ZIP file.
	The default is the UDE package of the current model version in the artifacts folder.

	.EXAMPLE
	PS> .\_Scripts\PPAC_DeployPackage.ps1 -Environment https://contoso-dev.crm4.dynamics.com/

	Deploys the UDE package of the current model version.

	.EXAMPLE
	PS> .\_Scripts\PPAC_DeployPackage.ps1 -Environment https://contoso-dev.crm4.dynamics.com/ -PackagePath .\artifacts\DeployablePackage\DocentricAXInvoiceDeliveryAgent-1.0.0-UDE.zip

	Deploys the specified UDE package ZIP file.

	.EXAMPLE
	PS> .\_Scripts\PPAC_DeployPackage.ps1 -Environment https://contoso-dev.crm4.dynamics.com/ -WhatIf

	Checks the Power Platform CLI and the package, and does not deploy.
#>

# Input parameters
[CmdletBinding(SupportsShouldProcess = $true)]
param
(
	[Parameter(Mandatory=$true,
		HelpMessage = 'The URL or the ID of the target Power Platform environment.')]
	[ValidateNotNullOrEmpty()]
	[String]$Environment,

	[Parameter(Mandatory=$false,
		HelpMessage = 'The TemplatePackage.dll of the UDE package folder, or the UDE package ZIP file.')]
	[String]$PackagePath
)

#Requires -Version 5.1

## https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'AOS_Common.psm1') -Force

try
{
	if ([System.String]::IsNullOrWhiteSpace($PackagePath))
	{
		$PackagePath = Join-Path (Get-DidaUdePackageFolder) 'TemplatePackage.dll'
	}
	if (!(Test-Path -Path $PackagePath -PathType Leaf))
	{
		throw "The package is missing: $PackagePath. Create it first (.\_Scripts\AOS_ExportDeployablePackage.ps1 -Target UDE)."
	}
	$PackagePath = (Resolve-Path -Path $PackagePath).ProviderPath
	if ([System.IO.Path]::GetExtension($PackagePath) -notin @('.dll', '.zip'))
	{
		throw "The package must be the TemplatePackage.dll of the UDE package folder or the UDE package ZIP file: $PackagePath"
	}

	Write-Host "Environment: $Environment"
	Write-Host "Package: $PackagePath`n"

	$PacPath = Install-DidaPacCli

	if ($PSCmdlet.ShouldProcess($Environment, "Deploy the package '$PackagePath'"))
	{
		Connect-DidaPacEnvironment -PacPath $PacPath -Environment $Environment

		$LogPath = Join-Path (Reset-DidaArtifactsFolder -Name 'PPAC\Deploy') 'PackageDeploy.log'
		Write-Host "`nDeploying the package. This can take some time...`n"
		Invoke-DidaTool -FilePath $PacPath -ArgumentList @(
			'package', 'deploy',
			'--package', $PackagePath,
			'--environment', $Environment,
			'--logFile', $LogPath,
			'--logConsole')

		Write-Host "`nThe package was deployed to: $Environment" -ForegroundColor Green
		Write-Host "Log: $LogPath"
	}

	Write-Host "`nScript completed."
}
catch
{
	Write-Host "`nThe package deployment failed: $($_.Exception.Message)" -ForegroundColor Red
	exit 1
}
finally
{
	Set-StrictMode -Off
}
