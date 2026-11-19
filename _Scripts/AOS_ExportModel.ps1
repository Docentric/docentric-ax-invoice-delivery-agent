<#
	.SYNOPSIS
	Exports the D365FO model DocentricAXInvoiceDeliveryAgent to a model file (.axmodel).

	.DESCRIPTION
	*** Script version: AOS_ExportModel.ps1 v1.0 ***

	Exports the model source with ModelUtil.exe to 'artifacts\Model\DocentricAXInvoiceDeliveryAgent-<version>.axmodel'.
	The version is read from the model descriptor (VersionMajor.VersionMinor.VersionBuild).
	A model file contains the source code only. Import it with 'ModelUtil.exe -import' and build the model on the target environment.

	The model must be in PackagesLocalDirectory (run .\AOS_CreateMetadataSymbolicLinks.ps1 first).

	.PARAMETER PackagesLocalFolder
	Specify a custom AOS PackagesLocalDirectory path.

	.EXAMPLE
	PS> .\_Scripts\AOS_ExportModel.ps1

	Exports the model to the artifacts\Model folder.

	.EXAMPLE
	PS> .\_Scripts\AOS_ExportModel.ps1 -PackagesLocalFolder "C:\CustomAOS\PackagesLocalDirectory"

	Exports the model from the specified folder.
#>

# Input parameters
param
(
	[Parameter(Mandatory=$false,
		HelpMessage = 'If specified this will be the PackagesLocalDirectory folder that contains the model.')]
	[String]$PackagesLocalFolder
)

## https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'AOS_Common.psm1') -Force

try
{
	$AOSMetadataPath = Resolve-AosPackagesLocalFolder -PackagesLocalFolder $PackagesLocalFolder
	$Model = Get-DidaModel -PackagesLocalFolder $AOSMetadataPath
	$OutputPath = Reset-DidaArtifactsFolder -Name 'Model'

	Write-Host "AOS PackagesLocal Folder: $AOSMetadataPath"
	Write-Host "Model: $($Model.Module) ($($Model.Name)) v$($Model.Version)"
	Write-Host "Output Folder: $OutputPath"

	Write-Host "`nExporting model...`n"
	Invoke-DidaTool -FilePath (Join-Path $AOSMetadataPath 'bin\ModelUtil.exe') -ArgumentList @(
		'-export',
		"-metadatastorepath=$AOSMetadataPath",
		"-modelname=$($Model.Module)",
		"-outputpath=$OutputPath")

	## ModelUtil.exe names the file '<Module>-<Publisher>.axmodel'. Add the version to the name.
	$ExportedFile = @(Get-ChildItem -Path $OutputPath -Filter '*.axmodel' -File)
	if ($ExportedFile.Count -ne 1)
	{
		throw "ModelUtil.exe did not create one model file in '$OutputPath'."
	}
	$ModelFilePath = Join-Path $OutputPath "$($Model.Module)-$($Model.Version).axmodel"
	Move-Item -Path $ExportedFile[0].FullName -Destination $ModelFilePath

	Write-Host "`nThe model was exported: $ModelFilePath" -ForegroundColor Green
	Write-Host "`nScript completed."
}
catch
{
	Write-Host "`nThe model export failed: $($_.Exception.Message)" -ForegroundColor Red
	exit 1
}
finally
{
	Set-StrictMode -Off
}
