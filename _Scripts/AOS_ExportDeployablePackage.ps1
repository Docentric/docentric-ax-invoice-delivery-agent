<#
	.SYNOPSIS
	Creates the deployable packages of the D365FO model DocentricAXInvoiceDeliveryAgent for LCS and UDE environments.

	.DESCRIPTION
	*** Script version: AOS_ExportDeployablePackage.ps1 v1.0 ***

	Creates the deployable packages from the build output of the model, with the D365FO packaging tools in
	AOSService\PackagesLocalDirectory\bin (CreatePackage.psm1, Microsoft.Dynamics.AXCreateDeployablePackageBase.dll, ModelUtil.exe):

	- LCS: 'artifacts\DeployablePackage\LCS\DocentricAXInvoiceDeliveryAgent-<version>.zip'
	  A deployable package (runtime package merged with the deployable base package).
	  Upload it to the LCS Asset library, or apply it to a cloud-hosted environment.
	- UDE: 'artifacts\DeployablePackage\UDE\DocentricAXInvoiceDeliveryAgent-<version>\'
	  A unified package, converted from the LCS deployable package with 'ModelUtil.exe -convertToUnifiedPackage'.
	  Deploy it to a Power Platform (UDE) environment with 'pac package deploy --package <folder>\TemplatePackage.dll'.

	The version is read from the model descriptor (VersionMajor.VersionMinor.VersionBuild).
	Build the model first (.\_Scripts\AOS_BuildModel.ps1 or Visual Studio). The script does not build the model.

	*** NOTE: Run the script in Windows PowerShell 5.1. The packaging tools use .NET Framework assemblies.

	.PARAMETER PackagesLocalFolder
	Specify a custom AOS PackagesLocalDirectory path.

	.PARAMETER Target
	The environment type to create the package for: All (default), LCS or UDE.

	.EXAMPLE
	PS> .\_Scripts\AOS_ExportDeployablePackage.ps1

	Creates the LCS and the UDE package.

	.EXAMPLE
	PS> .\_Scripts\AOS_ExportDeployablePackage.ps1 -Target UDE

	Creates only the UDE package.
#>

# Input parameters
param
(
	[Parameter(Mandatory=$false,
		HelpMessage = 'If specified this will be the PackagesLocalDirectory folder that contains the model.')]
	[String]$PackagesLocalFolder,

	[Parameter(Mandatory=$false,
		HelpMessage = 'The environment type to create the package for: All, LCS or UDE.')]
	[ValidateSet('All', 'LCS', 'UDE')]
	[String]$Target = 'All'
)

#Requires -Version 5.1
#Requires -PSEdition Desktop

## https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'AOS_Common.psm1') -Force

$TempPath = $null
try
{
	$AOSMetadataPath = Resolve-AosPackagesLocalFolder -PackagesLocalFolder $PackagesLocalFolder
	$Model = Get-DidaModel -PackagesLocalFolder $AOSMetadataPath
	$ToolsPath = Join-Path $AOSMetadataPath 'bin'

	$ModelAssemblyPath = Join-Path $Model.BinFolder "Dynamics.AX.$($Model.Module).dll"
	if (!(Test-Path -Path $ModelAssemblyPath -PathType Leaf))
	{
		throw "The build output of the model is missing: $ModelAssemblyPath. Build the model first (.\_Scripts\AOS_BuildModel.ps1)."
	}

	foreach ($RequiredFile in @('CreatePackage.psm1', 'Microsoft.Dynamics.AXCreateDeployablePackageBase.dll', 'BaseMetadataDeployablePackage.zip', 'ModelUtil.exe'))
	{
		if (!(Test-Path -Path (Join-Path $ToolsPath $RequiredFile) -PathType Leaf))
		{
			throw "The packaging tool '$RequiredFile' is missing in '$ToolsPath'."
		}
	}

	## The platform version is used as the version of the runtime package, as in the D365FO build automation (DynamicsSDK\GeneratePackage.ps1).
	$KernelVersion = '7.0.0.0'
	$KernelPath = Join-Path $ToolsPath 'AOSKernel.dll'
	if (Test-Path -Path $KernelPath -PathType Leaf)
	{
		$KernelVersion = (Get-Item -Path $KernelPath).VersionInfo.FileVersion
	}

	## The web root is only used for additional files with destination 'AOSWeb' (FileLocations.xml).
	$WebRootPath = Join-Path (Split-Path -Path $AOSMetadataPath -Parent) 'webroot'
	if (!(Test-Path -Path $WebRootPath -PathType Container))
	{
		$WebRootPath = ''
	}

	$TempPath = Reset-DidaArtifactsFolder -Name 'DeployablePackage\_temp'
	$PackageFileName = "$($Model.Module)-$($Model.Version)"

	Write-Host "AOS PackagesLocal Folder: $AOSMetadataPath"
	Write-Host "Model: $($Model.Module) ($($Model.Name)) v$($Model.Version)"
	Write-Host "Platform Version: $KernelVersion"
	Write-Host "Target: $Target"

	## Copy the build output to a staging folder. The packaging tool adds files to the package folder,
	## and the model folder in PackagesLocalDirectory is the repository folder.
	Write-Host "`nCopying the build output to the staging folder...`n"
	$StagingPath = Join-Path $TempPath "Staging\$($Model.Module)"
	New-Item -Path $StagingPath -ItemType Directory -Force | Out-Null
	foreach ($OutputFolder in @('bin', 'Resources', 'Reports'))
	{
		$SourcePath = Join-Path $Model.Folder $OutputFolder
		if (Test-Path -Path $SourcePath -PathType Container)
		{
			Copy-Item -Path $SourcePath -Destination $StagingPath -Recurse -Force
		}
	}
	Get-ChildItem -Path $Model.Folder -File | Where-Object { $_.Extension -eq '.xref' -or $_.Name -eq 'FileLocations.xml' } |
		Copy-Item -Destination $StagingPath -Force
	Get-ChildItem -Path $StagingPath -Filter '*.delete' -File -Recurse | Remove-Item -Force

	Write-Host "Creating the runtime package...`n"
	$RuntimePath = Join-Path $TempPath 'Runtime'
	New-Item -Path $RuntimePath -ItemType Directory -Force | Out-Null
	Import-Module (Join-Path $ToolsPath 'CreatePackage.psm1') -Function 'New-XppRuntimePackage'
	New-XppRuntimePackage -packageName $Model.Module -packageDrop $StagingPath -outputDir $RuntimePath -metadataDir $AOSMetadataPath `
		-packageVersion $KernelVersion -binDir $ToolsPath -copyRight $Model.Publisher -webRoot $WebRootPath -enforceVersionCheck $true | Out-Null
	if (@(Get-ChildItem -Path $RuntimePath -File).Count -eq 0)
	{
		throw "The runtime package was not created in '$RuntimePath'."
	}

	Write-Host "`nCreating the LCS deployable package...`n"
	Add-Type -Path (Join-Path $ToolsPath 'Microsoft.Dynamics.AXCreateDeployablePackageBase.dll')
	$CombinedPackagePath = Join-Path $RuntimePath "AXCombinedRuntime_$($KernelVersion)_$($Model.Version).zip"
	[Microsoft.Dynamics.AXCreateDeployablePackageBase.BuildDeployablePackages]::CreateMetadataPackage($RuntimePath, $CombinedPackagePath) | Out-Null

	$LcsPackagePath = Join-Path $TempPath "$PackageFileName.zip"
	$PackageCreated = [Microsoft.Dynamics.AXCreateDeployablePackageBase.BuildDeployablePackages]::MergePackage(
		(Join-Path $ToolsPath 'BaseMetadataDeployablePackage.zip'), $CombinedPackagePath, $LcsPackagePath, $true, [String]::Empty)
	if (!$PackageCreated -or !(Test-Path -Path $LcsPackagePath -PathType Leaf))
	{
		throw "The LCS deployable package was not created: $LcsPackagePath"
	}

	if ($Target -eq 'All' -or $Target -eq 'UDE')
	{
		Write-Host "Converting to the UDE unified package...`n"
		$UdePackagePath = Join-Path (Reset-DidaArtifactsFolder -Name 'DeployablePackage\UDE') $PackageFileName
		Invoke-DidaTool -FilePath (Join-Path $ToolsPath 'ModelUtil.exe') -ArgumentList @(
			'-convertToUnifiedPackage',
			"-file=$LcsPackagePath",
			"-outputpath=$UdePackagePath")
		if (!(Test-Path -Path (Join-Path $UdePackagePath 'TemplatePackage.dll') -PathType Leaf))
		{
			throw "The UDE unified package was not created: $UdePackagePath"
		}
		Write-Host "`nThe UDE unified package was created: $UdePackagePath" -ForegroundColor Green
	}

	if ($Target -eq 'All' -or $Target -eq 'LCS')
	{
		$LcsOutputPath = Join-Path (Reset-DidaArtifactsFolder -Name 'DeployablePackage\LCS') "$PackageFileName.zip"
		Move-Item -Path $LcsPackagePath -Destination $LcsOutputPath
		Write-Host "`nThe LCS deployable package was created: $LcsOutputPath" -ForegroundColor Green
	}

	Write-Host "`nScript completed."
}
catch
{
	Write-Host "`nThe package creation failed: $($_.Exception.Message)" -ForegroundColor Red
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
