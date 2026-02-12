function Test-IsWindows {
	return [System.Environment]::OSVersion.Platform -eq 'Win32NT'
}

function Get-rwGridViewAvailable {
	return (-not ([System.Environment]::GetEnvironmentVariable('SKIP_GRIDVIEW') -eq '1') `
		-and (Get-Command -Name Out-GridView -CommandType Cmdlet -ErrorAction SilentlyContinue))
}

function Get-rwDirToolsAutomation {
    return [System.Environment]::GetEnvironmentVariable('RW_DIRTOOLS_AUTO') -eq '1'
}

$script:SpectreConsoleAvailable = $null
function Test-rwSpectreAvailable {
	if ($null -ne $script:SpectreConsoleAvailable) {
		return $script:SpectreConsoleAvailable
	}

	try {
		$module = Get-Module -Name Spectre.Console -ListAvailable -ErrorAction Stop
		if ($module) {
			Import-Module Spectre.Console -ErrorAction Stop -WarningAction SilentlyContinue
			$script:SpectreConsoleAvailable = $true
			return $true
		}
	} catch {
		Write-Verbose "Spectre.Console unavailable: $($_.Exception.Message)"
	}

	$script:SpectreConsoleAvailable = $false
	return $false
}

if (Test-IsWindows) {
	$script:WindowsReservedDeviceNames = @('CON','PRN','AUX','NUL') + @(1..9 | ForEach-Object { "COM$_" }) + @(1..9 | ForEach-Object { "LPT$_" })
	$script:ReservedNamePattern = "^($($script:WindowsReservedDeviceNames -join '|'))(\.|:|\s)"
} else {
	$script:WindowsReservedDeviceNames = @()
	$script:ReservedNamePattern = $null
}

$publicPath = Join-Path -Path $PSScriptRoot -ChildPath "Public"
$publicFunctions = @("Get-rwDirPath.ps1", "New-rwDirPath.ps1", "Out-rwMenuCLI.ps1")

foreach ($file in $publicFunctions) {
	$fullPath = Join-Path $publicPath $file
	if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
		throw [System.IO.FileNotFoundException] "Expected function file '$fullPath' is missing."
	}
	try {
		. $fullPath
	} catch {
		throw "Failed to load '$file': $($_.Exception.Message)"
	}
}

$privatePath = Join-Path $PSScriptRoot 'Private'
Get-ChildItem -Path $privatePath -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}
