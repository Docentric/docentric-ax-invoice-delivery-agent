<#
	.SYNOPSIS
	Shared functions for the build and export scripts of the D365FO model DocInvoiceDeliveryAgent.

	.DESCRIPTION
	*** Script version: AOS_Common.psm1 v1.0 ***

	Used by AOS_BuildModel.ps1, AOS_ExportModel.ps1 and AOS_ExportDeployablePackage.ps1.
	Do not run this module directly.
#>

## https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode
Set-StrictMode -Version 3.0

$ModelModule = 'DocInvoiceDeliveryAgent'
$RepositoryRoot = Split-Path -Path $PSScriptRoot -Parent
$ArtifactsRoot = Join-Path $RepositoryRoot 'artifacts'

<#
	.SYNOPSIS
	Returns the full path of the AOS PackagesLocalDirectory folder.

	.PARAMETER PackagesLocalFolder
	A custom PackagesLocalDirectory path. If empty, the folder is searched for in the root of all fixed drives (for example C:\AOSService\PackagesLocalDirectory).
#>
function Resolve-AosPackagesLocalFolder
{
	param
	(
		[String]$PackagesLocalFolder
	)

	if (![System.String]::IsNullOrWhiteSpace($PackagesLocalFolder))
	{
		if (!(Test-Path -Path $PackagesLocalFolder -PathType Container))
		{
			throw "The specified PackagesLocalDirectory folder does not exist: $PackagesLocalFolder"
		}
		return (Resolve-Path -Path $PackagesLocalFolder).ProviderPath
	}

	foreach ($Drive in [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' -and $_.IsReady })
	{
		$Candidate = Join-Path $Drive.RootDirectory.FullName 'AOSService\PackagesLocalDirectory'
		if (Test-Path -Path $Candidate -PathType Container)
		{
			return $Candidate
		}
	}

	throw "The AOS PackagesLocalDirectory folder is missing (e.g., C:\AOSService\PackagesLocalDirectory). Use the -PackagesLocalFolder parameter."
}

<#
	.SYNOPSIS
	Returns the model information from the model descriptor in PackagesLocalDirectory.

	.DESCRIPTION
	Fails if the model is not in PackagesLocalDirectory. Shows a warning if the model folder is not a symbolic link to this repository,
	because the scripts would then use the source code of another location.

	.PARAMETER PackagesLocalFolder
	The full path of the PackagesLocalDirectory folder.
#>
function Get-DidaModel
{
	param
	(
		[Parameter(Mandatory = $true)]
		[String]$PackagesLocalFolder
	)

	$ModelFolder = Join-Path $PackagesLocalFolder $ModelModule
	$DescriptorPath = Join-Path $ModelFolder "Descriptor\$ModelModule.xml"
	if (!(Test-Path -Path $DescriptorPath -PathType Leaf))
	{
		throw "The model '$ModelModule' is missing in '$PackagesLocalFolder'. Run .\AOS_CreateMetadataSymbolicLinks.ps1 as administrator first."
	}

	$RepositoryModelFolder = Join-Path $RepositoryRoot "Metadata\$ModelModule"
	$ModelFolderItem = Get-Item -Path $ModelFolder
	if ($ModelFolderItem.LinkType -ne 'SymbolicLink' -or
		([String]@($ModelFolderItem.Target)[0]).TrimEnd('\') -ne $RepositoryModelFolder.TrimEnd('\'))
	{
		Write-Warning "The model folder '$ModelFolder' is not a symbolic link to '$RepositoryModelFolder'. The scripts use the model from '$ModelFolder'."
	}

	[xml]$Descriptor = Get-Content -Path $DescriptorPath -Raw
	$ModelInfo = $Descriptor.AxModelInfo

	return [PSCustomObject]@{
		Module       = $ModelModule
		Name         = $ModelInfo.Name
		Publisher    = $ModelInfo.Publisher
		Version      = '{0}.{1}.{2}' -f $ModelInfo.VersionMajor, $ModelInfo.VersionMinor, $ModelInfo.VersionBuild
		Folder       = $ModelFolder
		BinFolder    = Join-Path $ModelFolder 'bin'
		SourceFolder = Join-Path $ModelFolder $ModelModule
	}
}

<#
	.SYNOPSIS
	Runs a command-line tool and fails if its exit code is not 0.

	.PARAMETER FilePath
	The full path of the tool.

	.PARAMETER ArgumentList
	The arguments for the tool.
#>
function Invoke-DidaTool
{
	param
	(
		[Parameter(Mandatory = $true)]
		[String]$FilePath,

		[String[]]$ArgumentList = @()
	)

	$ToolName = [System.IO.Path]::GetFileName($FilePath)
	if (!(Test-Path -Path $FilePath -PathType Leaf))
	{
		throw "The tool '$ToolName' is missing: $FilePath"
	}

	Write-Host "  > $ToolName $($ArgumentList -join ' ')" -ForegroundColor DarkGray
	& $FilePath @ArgumentList | ForEach-Object { Write-Host "    $_" }
	if ($LASTEXITCODE -ne 0)
	{
		throw "'$ToolName' failed with exit code $LASTEXITCODE."
	}
}

<#
	.SYNOPSIS
	Shows the errors and warnings of a D365FO diagnostics XML log (compiler or best practice) and returns the number of errors.

	.PARAMETER XmlLogPath
	The full path of the XML log.

	.PARAMETER StepName
	The name of the build step that is shown in the summary.
#>
function Write-DidaDiagnostics
{
	param
	(
		[Parameter(Mandatory = $true)]
		[String]$XmlLogPath,

		[Parameter(Mandatory = $true)]
		[String]$StepName
	)

	if (!(Test-Path -Path $XmlLogPath -PathType Leaf))
	{
		Write-Host "  ${StepName}: The diagnostics log is missing: $XmlLogPath" -ForegroundColor Yellow
		return 0
	}

	[xml]$Log = Get-Content -Path $XmlLogPath -Raw
	$ErrorCount = 0
	$WarningCount = 0
	foreach ($Diagnostic in $Log.SelectNodes('/Diagnostics/Items/Diagnostic'))
	{
		$Severity = Get-DidaNodeText $Diagnostic 'Severity'
		if ($Severity -eq 'Error' -or $Severity -eq 'Fatal')
		{
			$ErrorCount++
			$Color = 'Red'
		}
		elseif ($Severity -eq 'Warning')
		{
			$WarningCount++
			$Color = 'Yellow'
		}
		else
		{
			continue
		}

		$Line = Get-DidaNodeText $Diagnostic 'Line'
		Write-Host ("  {0}: {1} ({2}): {3} [{4}]" -f $Severity, (Get-DidaNodeText $Diagnostic 'Path'), $Line, (Get-DidaNodeText $Diagnostic 'Message'), (Get-DidaNodeText $Diagnostic 'Moniker')) -ForegroundColor $Color
	}

	$SummaryColor = if ($ErrorCount -gt 0) { 'Red' } elseif ($WarningCount -gt 0) { 'Yellow' } else { 'Green' }
	Write-Host "  ${StepName}: $ErrorCount error(s), $WarningCount warning(s)." -ForegroundColor $SummaryColor
	return $ErrorCount
}

function Get-DidaNodeText
{
	param
	(
		[System.Xml.XmlNode]$Node,
		[String]$ChildName
	)

	$Child = $Node.SelectSingleNode($ChildName)
	if ($Child) { return $Child.InnerText }
	return ''
}

<#
	.SYNOPSIS
	Deletes and creates again a sub folder of the artifacts folder in the repository root, and returns its full path.

	.PARAMETER Name
	The relative path of the sub folder (for example 'Build' or 'DeployablePackage\LCS').
#>
function Reset-DidaArtifactsFolder
{
	param
	(
		[Parameter(Mandatory = $true)]
		[String]$Name
	)

	$Folder = Join-Path $ArtifactsRoot $Name
	if (Test-Path -Path $Folder)
	{
		Remove-Item -Path $Folder -Recurse -Force
	}
	New-Item -Path $Folder -ItemType Directory -Force | Out-Null
	return $Folder
}

Export-ModuleMember -Function Resolve-AosPackagesLocalFolder, Get-DidaModel, Invoke-DidaTool, Write-DidaDiagnostics, Reset-DidaArtifactsFolder
