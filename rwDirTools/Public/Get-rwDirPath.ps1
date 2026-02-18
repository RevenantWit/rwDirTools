<#
.SYNOPSIS
Select directories with filters, validation, and a GUI/CLI fallback.

.DESCRIPTION
Enumerates subfolders under a base path, applies exclusions and optional empty-folder filtering, then lets the user pick single or multiple directories. It favors Out-GridView when available and falls back to the menu helper (which keeps the selection indexes for downstream callers).

.PARAMETER Path
Path to scan for directories. Pipeline input supported; defaults to the current location.

.PARAMETER ExcludeDir
Directory names to exclude from being selected (Supports wildcards.).

.PARAMETER NoEmptyDir
Skip directories that contain no entries.

.PARAMETER SingleDir
Limit the selection to a single directory.

.PARAMETER Name
Output only the folder names instead of full paths.

.PARAMETER Object
Return `DirectoryInfo` instances for richer metadata access.

.PARAMETER Title
Prompt header shown in the UI (default: "Select A Folder").

.EXAMPLE
Get-rwDirPath -Path .\Input -SingleDir
# Select one folder, returns the full path.

.EXAMPLE
Get-rwDirPath -Path .\Mods -NoEmptyDir | Sort-Object
# Pick multiple non-empty folders and keep the canonical paths.

.EXAMPLE
Get-rwDirPath -Title "Pick targets" -Name | ForEach-Object { "Chosen: $_" }
# Return names only for display.

.NOTES
Always returns full paths unless -Name or -Object is specified. Works in both GUI and CLI hosts.
#>
Function Get-rwDirPath {
	[CmdletBinding()]
	[OutputType([string[]])]
	[OutputType([System.IO.DirectoryInfo[]])]
	param(
		[Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Path = (Get-Location).Path,

		[Parameter()]
		[string[]]$ExcludeDir = @(),

		[Parameter()]
		[switch]$NoEmptyDir,

		[Parameter()]
		[switch]$SingleDir,

		[Parameter()]
		[switch]$Name,

		[Parameter()]
		[switch]$Object,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateLength(1, 200)]
		[string]$Title = "Select A Folder"
	)

	process {
		Write-Verbose "Get-rwDirPath: Path='$Path' SingleDir=$SingleDir NoEmptyDir=$NoEmptyDir"

		if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
			Write-Warning "Path '$Path' does not exist or is not a directory."
			return @()
		}

		if ($Name -and $Object) {
			throw [System.ArgumentException] "`-Name` and `-Object` are mutually exclusive. Choose one."
		}

		try {
			$folders = Get-rwDirPathFiltered $Path -ExcludeDir $ExcludeDir -NoEmptyDir:$NoEmptyDir
			If (-not $folders) { return @() }
		} catch {
			Write-Error "Error enumerating directories $($_.Exception.Message)"
			return @()
		}

		$selected = Get-rwDirFromUI -Title $Title -Folders $folders -SingleDir:$SingleDir
		
		If (-not $selected) { return @() }

		Write-Verbose "After Get-rwDirFromUI: Type=$($selected.GetType().FullName) Count=$($selected.Count)"
		return Out-rwDirSelection -Selection $selected -ReturnName:$Name -ReturnObject:$Object
	}
}

function Get-rwDirPathFiltered {
	param(
		[string]$Path,
		[string[]]$ExcludeDir,
		[switch]$NoEmptyDir
	)

	$dirs = Get-ChildItem -LiteralPath $Path -Directory -ErrorAction SilentlyContinue
	if ($ExcludeDir) {
		$dirs = $dirs | Where-Object {
			$name = $_.Name
			-not ($ExcludeDir | Where-Object { $name -like $_ })
		}
	}

	If ($NoEmptyDir) {
		$dirs = $dirs | Where-Object { 
			$null -ne ([System.IO.Directory]::EnumerateFileSystemEntries($_.FullName) | Select-Object -First 1)
		}
	}

	return Ensure-rwArray $dirs
}
