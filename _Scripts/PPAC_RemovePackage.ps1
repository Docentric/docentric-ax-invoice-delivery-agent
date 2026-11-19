<#
	.SYNOPSIS
	Removes the D365FO model DocentricAXInvoiceDeliveryAgent from a Power Platform environment.

	.DESCRIPTION
	*** Script version: PPAC_RemovePackage.ps1 v1.0 ***

	Removes the deployed model from a Power Platform environment with finance and operations apps (for example, a unified
	developer environment that you manage in the Power Platform admin center). The script uploads the model package with
	'pac package deploy --package-type erp --build-type Delete'. The finance and operations environment then removes the
	artifacts of the module 'docentricaxinvoicedeliveryagent'.

	*** NOTE: '--package-type erp' and '--build-type Delete' are preview features of the Power Platform CLI.

	The model package is 'PackageAssets\docentricaxinvoicedeliveryagent_<n>_<n>_<n>_<n>_managed.zip' in the UDE unified package folder.
	The Power Platform CLI gets the module name from this file name, and adds the delete instruction (fnomoduledefinition.json)
	to the file. Thus the script uploads a temporary copy, and the UDE package does not change.

	Before the removal, make sure that no other module on the environment references the module.

	Before the removal, the script makes sure that the latest version of the Power Platform CLI (Windows MSI) is installed.
	If the CLI is not installed, the script installs it for the current user. If a newer version is available, the script installs it.
	If the Power Platform CLI has no auth profile, the script opens the sign-in.

	Create the UDE package first with '.\_Scripts\AOS_ExportDeployablePackage.ps1'. The script asks for confirmation before the removal.

	.PARAMETER Environment
	The URL (for example https://contoso-dev.crm4.dynamics.com/) or the ID of the Power Platform environment.

	.PARAMETER PackagePath
	The model package file 'docentricaxinvoicedeliveryagent_<n>_<n>_<n>_<n>_managed.zip'.
	The default is the file in the UDE package folder of the current model version in the artifacts folder.

	.EXAMPLE
	PS> .\_Scripts\PPAC_RemovePackage.ps1 -Environment https://contoso-dev.crm4.dynamics.com/

	Removes the model from the environment after confirmation.

	.EXAMPLE
	PS> .\_Scripts\PPAC_RemovePackage.ps1 -Environment https://contoso-dev.crm4.dynamics.com/ -Confirm:$false

	Removes the model from the environment without confirmation.

	.EXAMPLE
	PS> .\_Scripts\PPAC_RemovePackage.ps1 -Environment https://contoso-dev.crm4.dynamics.com/ -WhatIf

	Checks the Power Platform CLI and the package, and does not remove the model.
#>

# Input parameters
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param
(
	[Parameter(Mandatory=$true,
		HelpMessage = 'The URL or the ID of the Power Platform environment.')]
	[ValidateNotNullOrEmpty()]
	[String]$Environment,

	[Parameter(Mandatory=$false,
		HelpMessage = 'The model package file docentricaxinvoicedeliveryagent_<n>_<n>_<n>_<n>_managed.zip.')]
	[String]$PackagePath
)

#Requires -Version 5.1

## https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'AOS_Common.psm1') -Force

$ModuleName = 'docentricaxinvoicedeliveryagent'
## The Power Platform CLI gets the module name from this file name pattern.
$PackageFilePattern = "^$($ModuleName)_\d+_\d+_\d+_\d+_managed\.zip$"

$TempPath = $null
try
{
	if ([System.String]::IsNullOrWhiteSpace($PackagePath))
	{
		$AssetsPath = Join-Path (Get-DidaUdePackageFolder) 'PackageAssets'
		if (!(Test-Path -Path $AssetsPath -PathType Container))
		{
			throw "The UDE package is missing: $AssetsPath. Create it first (.\_Scripts\AOS_ExportDeployablePackage.ps1 -Target UDE)."
		}
		$PackageFiles = @(Get-ChildItem -Path $AssetsPath -File | Where-Object { $_.Name -match $PackageFilePattern })
		if ($PackageFiles.Count -ne 1)
		{
			throw "The UDE package must contain one model package file '$($ModuleName)_<n>_<n>_<n>_<n>_managed.zip': $AssetsPath"
		}
		$PackagePath = $PackageFiles[0].FullName
	}
	if (!(Test-Path -Path $PackagePath -PathType Leaf))
	{
		throw "The model package is missing: $PackagePath"
	}
	$PackagePath = (Resolve-Path -Path $PackagePath).ProviderPath
	$PackageFileName = [System.IO.Path]::GetFileName($PackagePath)
	if ($PackageFileName -notmatch $PackageFilePattern)
	{
		throw "The model package file name must be '$($ModuleName)_<n>_<n>_<n>_<n>_managed.zip': $PackageFileName"
	}

	Write-Host "Environment: $Environment"
	Write-Host "Module: $ModuleName"
	Write-Host "Package: $PackagePath`n"

	$PacPath = Install-DidaPacCli

	if ($PSCmdlet.ShouldProcess($Environment, "Remove the module '$ModuleName'"))
	{
		Connect-DidaPacEnvironment -PacPath $PacPath -Environment $Environment

		## The Power Platform CLI changes the uploaded file. Keep the file name, because the CLI gets the module name from it.
		$TempPath = Reset-DidaArtifactsFolder -Name 'PPAC\_temp'
		$UploadPath = Join-Path $TempPath $PackageFileName
		Copy-Item -Path $PackagePath -Destination $UploadPath

		Write-Host "`nRemoving the module. This can take some time...`n"
		Invoke-DidaTool -FilePath $PacPath -ArgumentList @(
			'package', 'deploy',
			'--package-type', 'erp',
			'--build-type', 'Delete',
			'--package', $UploadPath,
			'--environment', $Environment)

		Write-Host "`nThe module '$ModuleName' was removed from: $Environment" -ForegroundColor Green
	}

	Write-Host "`nScript completed."
}
catch
{
	Write-Host "`nThe module removal failed: $($_.Exception.Message)" -ForegroundColor Red
	exit 1
}
finally
{
	if ($TempPath -and (Test-Path -Path $TempPath))
	{
		Remove-Item -Path $TempPath -Recurse -Force -ErrorAction SilentlyContinue
	}
	Set-StrictMode -Off
}
