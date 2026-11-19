<#
	.SYNOPSIS
	Builds the D365FO model DocentricInvoiceDeliveryAgent.

	.DESCRIPTION
	*** Script version: AOS_BuildModel.ps1 v1.0 ***

	Builds the model with the D365FO build tools in AOSService\PackagesLocalDirectory\bin, in the same sequence
	as the D365FO build automation:

	1. Compiles the X++ code (xppc.exe), updates the cross references and runs the AppChecker rules.
	2. Compiles the labels (LabelC.exe), if the model has label files.
	3. Compiles the reports (ReportsC.exe), if the model has reports.
	4. Runs the Best Practice checks (xppbp.exe), unless -SkipBestPractices is specified.

	The build output is written to the model folder in PackagesLocalDirectory, as with a build in Visual Studio.
	The logs are written to the 'artifacts\Build' folder in the repository.
	The script fails if a step has errors. Warnings are shown, but they do not fail the build.

	The model must be in PackagesLocalDirectory (run .\AOS_CreateMetadataSymbolicLinks.ps1 first).
	Do not build the model in Visual Studio at the same time.

	.PARAMETER PackagesLocalFolder
	Specify a custom AOS PackagesLocalDirectory path.

	.PARAMETER SkipBestPractices
	Do not run the Best Practice checks.

	.EXAMPLE
	PS> .\_Scripts\AOS_BuildModel.ps1

	Builds the model and runs the Best Practice checks.

	.EXAMPLE
	PS> .\_Scripts\AOS_BuildModel.ps1 -PackagesLocalFolder "C:\CustomAOS\PackagesLocalDirectory" -SkipBestPractices

	Builds the model in the specified folder without the Best Practice checks.
#>

# Input parameters
param
(
	[Parameter(Mandatory=$false,
		HelpMessage = 'If specified this will be the PackagesLocalDirectory folder that contains the model.')]
	[String]$PackagesLocalFolder,

	[Parameter(Mandatory=$false,
		HelpMessage = 'If specified the Best Practice checks are not run.')]
	[Switch]$SkipBestPractices
)

## https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'AOS_Common.psm1') -Force

try
{
	$AOSMetadataPath = Resolve-AosPackagesLocalFolder -PackagesLocalFolder $PackagesLocalFolder
	$Model = Get-DidaModel -PackagesLocalFolder $AOSMetadataPath
	$ToolsPath = Join-Path $AOSMetadataPath 'bin'
	$LogPath = Reset-DidaArtifactsFolder -Name 'Build'

	Write-Host "AOS PackagesLocal Folder: $AOSMetadataPath"
	Write-Host "Model: $($Model.Module) ($($Model.Name)) v$($Model.Version)"
	Write-Host "Log Folder: $LogPath"

	$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$ErrorCount = 0

	Write-Host "`nCompiling X++ code...`n"
	Invoke-DidaTool -FilePath (Join-Path $ToolsPath 'xppc.exe') -ArgumentList @(
		"-metadata=$AOSMetadataPath",
		"-compilermetadata=$AOSMetadataPath",
		"-modelmodule=$($Model.Module)",
		"-output=$($Model.BinFolder)",
		"-referenceFolder=$AOSMetadataPath",
		"-refPath=$($Model.BinFolder)",
		"-appBase=$ToolsPath",
		'-xref',
		'-RunAppcheckerRules',
		"-log=$LogPath\Xppc.log",
		"-xmlLog=$LogPath\Xppc.xml")
	$ErrorCount += Write-DidaDiagnostics -XmlLogPath "$LogPath\Xppc.xml" -StepName 'X++ compiler'
	if ($ErrorCount -gt 0)
	{
		throw "The X++ compiler reported $ErrorCount error(s)."
	}

	if (Test-Path -Path (Join-Path $Model.SourceFolder 'AxLabelFile\*.xml'))
	{
		Write-Host "`nCompiling labels...`n"
		Invoke-DidaTool -FilePath (Join-Path $ToolsPath 'LabelC.exe') -ArgumentList @(
			"-metadata=$AOSMetadataPath",
			"-modelmodule=$($Model.Module)",
			"-output=$($Model.Folder)\Resources",
			"-outlog=$LogPath\LabelC.log",
			"-errlog=$LogPath\LabelC.err.log")
		if ((Test-Path -Path "$LogPath\LabelC.err.log") -and (Get-Item -Path "$LogPath\LabelC.err.log").Length -gt 0)
		{
			Get-Content -Path "$LogPath\LabelC.err.log" | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
		}
	}
	else
	{
		Write-Host "`nThe model has no label files. Label compilation is skipped."
	}

	if (Test-Path -Path (Join-Path $Model.SourceFolder 'AxReport\*.xml'))
	{
		Write-Host "`nCompiling reports...`n"
		Invoke-DidaTool -FilePath (Join-Path $ToolsPath 'ReportsC.exe') -ArgumentList @(
			"-metadata=$AOSMetadataPath",
			"-modelmodule=$($Model.Module)",
			"-output=$($Model.Folder)\Reports",
			"-LabelsPath=$AOSMetadataPath",
			"-log=$LogPath\ReportsC.log",
			"-xmllog=$LogPath\ReportsC.xml")
		$ErrorCount += Write-DidaDiagnostics -XmlLogPath "$LogPath\ReportsC.xml" -StepName 'Report compiler'
	}
	else
	{
		Write-Host "`nThe model has no reports. Report compilation is skipped."
	}

	if ($SkipBestPractices)
	{
		Write-Host "`nThe Best Practice checks are skipped."
	}
	else
	{
		Write-Host "`nRunning Best Practice checks...`n"
		Invoke-DidaTool -FilePath (Join-Path $ToolsPath 'xppbp.exe') -ArgumentList @(
			"-metadata=$AOSMetadataPath",
			"-compilermetadata=$AOSMetadataPath",
			"-packagesRoot=$AOSMetadataPath",
			"-module=$($Model.Module)",
			"-model=$($Model.Module)",
			'-all',
			"-log=$LogPath\BPCheck.log",
			"-xmlLog=$LogPath\BPCheck.xml")
		$ErrorCount += Write-DidaDiagnostics -XmlLogPath "$LogPath\BPCheck.xml" -StepName 'Best Practice checks'
	}

	if ($ErrorCount -gt 0)
	{
		throw "The build reported $ErrorCount error(s)."
	}

	Write-Host "`nThe build completed in $($Stopwatch.Elapsed.ToString('hh\:mm\:ss')). Restart the AOS (for example, with iisreset) to load the new binaries." -ForegroundColor Green
	Write-Host "`nScript completed."
}
catch
{
	Write-Host "`nThe build failed: $($_.Exception.Message)" -ForegroundColor Red
	exit 1
}
finally
{
	Set-StrictMode -Off
}
