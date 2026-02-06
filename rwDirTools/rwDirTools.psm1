# Module-level constants and compiled patterns for performance
if ([System.Environment]::OSVersion.Platform -eq 'Win32NT') {
    $script:WindowsReservedDeviceNames = @('CON','PRN','AUX','NUL') + @(1..9 | ForEach-Object { "COM$_" }) + @(1..9 | ForEach-Object { "LPT$_" })
    # Pre-compile regex pattern for reserved names with special characters
    $script:ReservedNamePattern = "^($($script:WindowsReservedDeviceNames -join '|'))(\.|:|\s)"
    Write-Verbose "rwDirTools module loaded (Windows mode). Reserved device names: $($script:WindowsReservedDeviceNames.Count) items. Pattern cached for performance."
} else {
    $script:WindowsReservedDeviceNames = @()
    $script:ReservedNamePattern = $null
    Write-Verbose "rwDirTools module loaded (non-Windows mode). Platform-specific validations disabled."
}

# Dot-source all public functions (cross-platform path handling)
$publicPath = Join-Path -Path $PSScriptRoot -ChildPath "Public"
$functionCount = 0
Get-ChildItem -Path $publicPath -Filter *.ps1 -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Verbose "Loading function from: $($_.Name)"
    . $_.FullName
    $functionCount++
}

Write-Verbose "rwDirTools module initialization complete. Loaded $functionCount public function(s)."
