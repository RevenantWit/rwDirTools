<#
.SYNOPSIS
Interactive menu helper that returns selected values.

.DESCRIPTION
Unified interface for single selection, multi-selection, and yes/no prompts. Automatically detects and uses Spectre.Console if available, falls back to CLI.

.PARAMETER Title
Question or heading. Default: "Options"

.PARAMETER Options
Menu choices (required for Single/Multiple modes).

.PARAMETER OutputMode
Prompt type: Single, Multiple, or YesNo. Default: Single.

.PARAMETER DefaultSelection
Zero-based index of default option (Single mode only). Default: -1.

.PARAMETER CancelLabel
Cancel button text. Default: "Cancel".

.PARAMETER PreferredUI
UI preference: Auto (detect), Spectre (force), or CLI (force). Default: Auto.

.EXAMPLE
$action = Out-rwMenuCLI -Title 'Choose' -Options @('Start','Stop') -OutputMode Single
# Returns: "Start" or "Stop"

.EXAMPLE
$items = Out-rwMenuCLI -Title 'Pick' -Options @('A','B','C') -OutputMode Multiple
# Returns: @('B','A') preserving user order

.EXAMPLE
if (Out-rwMenuCLI -Title 'Continue?' -OutputMode YesNo) { 'OK' }
# Returns: $true or $false
#>
function Out-rwMenuCLI {
	[CmdletBinding()]
	[OutputType([string])]
	[OutputType([string[]])]
	[OutputType([bool])]
	param(
		[ValidateNotNullOrEmpty()]
		[ValidateLength(1, 200)]
		[string]$Title = 'Options',

		[string[]]$Options,

		[ValidateSet('Single','Multiple','YesNo')]
		[string]$OutputMode = 'Single',

		[int]$DefaultSelection = -1,

		[ValidateNotNullOrEmpty()]
		[ValidateLength(1, 100)]
		[string]$CancelLabel = 'Cancel',

		[ValidateSet('Auto','Spectre','CLI')]
		[string]$PreferredUI = 'Auto'
	)
	Write-Verbose "Out-rwMenuCLI: Title='$Title' OutputMode='$OutputMode' Options.Count=$($Options.Count)"

	if ($OutputMode -in @('Single','Multiple') -and (-not $Options -or $Options.Count -eq 0)) {
		throw "Options are required for mode '$OutputMode'."
	}

	$options = if ($Options) { $Options | ForEach-Object { $_.ToString() } } else { @() }

	if ($OutputMode -eq 'Single' -and $options.Count -gt 0) {
		if ($DefaultSelection -lt -1 -or $DefaultSelection -ge $options.Count) {
			throw "DefaultSelection $DefaultSelection is outside the available options."
		}
	}

	if (Get-rwDirToolsAutomation) {
		return Get-rwAutomatedMenuSelection -OutputMode $OutputMode -Options $options -DefaultSelection $DefaultSelection
	}

	$useUI = if (Test-rwSpectreAvailable) { 'Spectre' } else { 'CLI' }
	if ($PreferredUI -eq 'CLI') { $useUI = 'CLI' }
	if ($PreferredUI -eq 'Spectre' -and $useUI -ne 'Spectre') { Write-Warning 'Spectre unavailable, using CLI' }

	if ($useUI -eq 'Spectre') {
		$result = Show-rwSpectreMenu -Title $Title -Options $options -OutputMode $OutputMode -DefaultSelection $DefaultSelection
		if ($null -eq $result -and $OutputMode -ne 'YesNo') {
			Write-Warning 'Spectre rendering failed, using CLI fallback'
			$result = Show-rwCLIMenu -Title $Title -Options $options -OutputMode $OutputMode -DefaultSelection $DefaultSelection -CancelLabel $CancelLabel
		}
		return $result
	} else {
		return Show-rwCLIMenu -Title $Title -Options $options -OutputMode $OutputMode -DefaultSelection $DefaultSelection -CancelLabel $CancelLabel
	}
}

function Get-rwAutomatedMenuSelection {
	param(
		[ValidateSet('Single','Multiple','YesNo')]
		[string]$OutputMode,
		[string[]]$Options,
		[int]$DefaultSelection = -1
	)

	if ($OutputMode -eq 'YesNo') {
		$raw = [Environment]::GetEnvironmentVariable('RW_DIRTOOLS_MENU_YESNO')
		$choice = if (-not [string]::IsNullOrWhiteSpace($raw)) {
			$raw -match '^(1|true|y|yes)$'
		} else {
			$true
		}
		return $choice
	}

	$rawSelection = [Environment]::GetEnvironmentVariable('RW_DIRTOOLS_MENU_SELECTION')
	$requested = @()
	if ($rawSelection) {
		$requested = @($rawSelection -split ',' | ForEach-Object {
			$trimmed = $_.Trim()
			if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
				$parsed = 0
				if ([int]::TryParse($trimmed, [ref]$parsed)) { $parsed }
			}
		})
	}

	$validIndexes = @($requested | Where-Object { $_ -ge 0 -and $_ -lt $Options.Count })

	if ($validIndexes.Count -eq 0) {
		if ($DefaultSelection -ge 0 -and $DefaultSelection -lt $Options.Count) {
			$validIndexes = @($DefaultSelection)
		} elseif ($Options.Count -gt 0) {
			$validIndexes = @(0)
		}
	}

	$selectedValues = @($validIndexes | ForEach-Object { $Options[$_] })
	if ($OutputMode -eq 'Single') { return $selectedValues[0] } else { return $selectedValues }
}
