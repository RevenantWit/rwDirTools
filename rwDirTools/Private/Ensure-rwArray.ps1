<#
.SYNOPSIS
Ensures input is always a proper array, regardless of PowerShell pipeline behavior.

.DESCRIPTION
PowerShell's Where-Object returns $null (0 items), scalar (1 item), or array (2+ items).
This function guarantees consistent array output for reliable downstream processing.

.NOTES
Uses simple array concatenation pattern for now.
#>
function Ensure-rwArray {
	param(
		[AllowNull()]
		[AllowEmptyCollection()]
		$InputObject
	)

	# @() + $null      → @()
	# @() + $scalar    → @($scalar)
	# @() + @(array)   → @(array)
	return @() + @($InputObject)
}
