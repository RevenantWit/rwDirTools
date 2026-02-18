<#
.SYNOPSIS
Creates a directory safely with validation and optional interactive prompts.

.DESCRIPTION
New-rwDirPath ensures a new folder is created under the specified parent, validating names, honoring reserved characters, and asking interactively when no name is supplied. Supports pipeline input, -WhatIf/-Confirm, and returns either paths, names, or DirectoryInfo objects.

.PARAMETER Path
Parent folder for the new directory. Defaults to the current location and accepts pipeline input.

.PARAMETER DirName
Name of the directory to create. If omitted, the helper prompts interactively (supports retries).

.PARAMETER Name
Return just the directory name instead of the path.

.PARAMETER Object
Return the DirectoryInfo object for the created folder.

.EXAMPLE
New-rwDirPath -Path C:\Temp -DirName "NewFolder" -Object
# Creates folder and returns DirectoryInfo metadata.

.EXAMPLE
New-rwDirPath -DirName "Temp" -Name
# Returns just the folder name after creation.

.NOTES
Validates against invalid characters and Windows reserved names, and respects ShouldProcess for safe execution.
#>
Function New-rwDirPath {
	[CmdletBinding(SupportsShouldProcess)]
	[OutputType([string])]
	param(
		[Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Path = (Get-Location).Path,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$DirName,

		[switch]$Name,

		[switch]$Object
	)

	process {
		Write-Verbose "New-rwDirPath: Path='$Path' DirName='$DirName'"

		if ($Name -and $Object) {
			throw [System.ArgumentException] "`-Name` and `-Object` are mutually exclusive."
		}

		$folderName = if ($DirName) { $DirName.Trim() } else { Read-rwNewDirName }
		if (-not $folderName) { return @() }

		$validation = Get-rwDirPathValidation -Path $Path -FolderName $folderName
		if (-not $validation.Success) {
			Write-Warning $validation.Message
			return @()
		}

		$creation = New-rwDirName -Path $Path -FolderName $validation.CanonicalName
		if ($creation.Result -ne 'Created' -or -not $creation.DirectoryInfo) { return @() }

		Write-Verbose "Before Out-rwDirSelection: Type=$($creation.DirectoryInfo.GetType().FullName)"
		return Out-rwDirSelection -Selection @($creation.DirectoryInfo) -ReturnName:$Name -ReturnObject:$Object
	}
}

function Get-rwDirPathValidation {
	param(
		[string]$Path,
		[string]$FolderName
	)

	if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
		return [pscustomobject]@{ Success = $false; Message = "Path '$Path' does not exist or is not a directory."; CanonicalName = $null }
	}

	if ($FolderName) { $name = $FolderName.Trim() } else { $name = $null }
	if (-not $name) {
		return [pscustomobject]@{ Success = $false; Message = 'Folder name cannot be empty.'; CanonicalName = $null }
	}

	$invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
	if ($name.IndexOfAny($invalidChars) -ne -1 -or $name.Contains('\') -or $name.Contains('/')) {
		return [pscustomobject]@{ Success = $false; Message = 'Folder name contains invalid characters.'; CanonicalName = $null }
	}

	if ($name -in @('.', '..')) {
		return [pscustomobject]@{ Success = $false; Message = "Folder name '$name' is reserved."; CanonicalName = $null }
	}

	if (Test-IsWindows) {
		$base = $name.TrimEnd('.', ' ').ToUpperInvariant()
		if ($script:WindowsReservedDeviceNames -contains $base -or ($script:ReservedNamePattern -and $name -match $script:ReservedNamePattern)) {
			return [pscustomobject]@{ Success = $false; Message = "Folder name '$name' is reserved on Windows."; CanonicalName = $null }
		}
	}

	return [pscustomobject]@{ Success = $true; Message = ''; CanonicalName = $name }
}

function New-rwDirName {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[string]$Path,
		[string]$FolderName
	)

	$folderPath = Join-Path -Path $Path -ChildPath $FolderName
	if (Test-Path -LiteralPath $folderPath -PathType Container) {
		return [pscustomobject]@{ Result = 'Exists'; DirectoryInfo = (Get-Item $folderPath); Message = 'Already exists' }
	}

	$automationEnabled = Get-rwDirToolsAutomation
	Write-Verbose "Automation mode: $automationEnabled for path: $folderPath"

	if (-not $automationEnabled) {
		if (-not $PSCmdlet.ShouldProcess($folderPath, 'Create directory')) {
			return [pscustomobject]@{ Result = 'Cancelled'; DirectoryInfo = $null; Message = 'Operation cancelled' }
		}
	}

	try {
		$confirmParam = if ($automationEnabled) { $false } else { $ConfirmPreference }
		$dir = New-Item -Path $folderPath -ItemType Directory -WhatIf:$WhatIfPreference -Confirm:$confirmParam -ErrorAction Stop
		return [pscustomobject]@{ Result = 'Created'; DirectoryInfo = $dir; Message = '' }
	} catch {
		return [pscustomobject]@{ Result = 'Failed'; DirectoryInfo = $null; Message = $_.Exception.Message }
	}
}

function Read-rwNewDirName {
	param([int]$MaxRetries = 5)

	for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
		if (-not $Host.UI.RawUI -or $env:CI) {
			Write-Warning 'Interactive input is not available in this session.'
			return $null
		}

		$input = Read-Host -Prompt "`nEnter New Folder Name"
		
		if (-not $input) {
			if ($attempt -lt $MaxRetries -and (Show-rwPromptYesNo -Title 'Nothing was entered. Try again?')) {
				continue
			}
			return $null
		}

		if (Show-rwPromptYesNo -Title "Use this folder name? $input") {
			return $input
		}
	}

	Write-Warning "Maximum retry attempts ($MaxRetries) reached."
	return $null
}
