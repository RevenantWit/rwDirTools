param(
	[string]$LogPath
)

$moduleRoot = $PSScriptRoot
$testsDir = Join-Path $moduleRoot "Tests"

if (-not $LogPath) {
	$LogPath = Join-Path $moduleRoot "TestResults_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
}

Write-Host "Starting tests at $(Get-Date)" -ForegroundColor Cyan
Write-Host "Module Root: $moduleRoot" -ForegroundColor Cyan
Write-Host "Tests Dir: $testsDir" -ForegroundColor Cyan
Write-Host "Log file: $LogPath" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

$ConfirmPreference = 'None'

Start-Transcript -Path $LogPath -Force

[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_AUTO', '1', 'Process')
[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_SELECTION', '0', 'Process')
[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_YESNO', '1', 'Process')

Write-Host "=== Diagnostic Info ===" -ForegroundColor Yellow
Write-Host "ConfirmPreference: $ConfirmPreference" -ForegroundColor Yellow
Write-Host "WhatIfPreference: $WhatIfPreference" -ForegroundColor Yellow
Write-Host "VerbosePreference: $VerbosePreference" -ForegroundColor Yellow
Write-Host "===================" -ForegroundColor Yellow
Write-Host ""

try {
	Remove-Module rwDirTools -Force -ErrorAction SilentlyContinue

	Write-Host "Importing rwDirTools..." -ForegroundColor Cyan
	Import-Module "$moduleRoot\rwDirTools.psd1" -Force
	Write-Host "Import complete`n" -ForegroundColor Green
	
	Write-Host "Running full test suite..." -ForegroundColor Cyan
	Write-Host "================================================`n" -ForegroundColor Cyan

	$results = Invoke-Pester -Path $testsDir -PassThru
	
	Write-Host "`n================================================" -ForegroundColor Cyan
	Write-Host "Test Summary" -ForegroundColor Cyan
	Write-Host "================================================"
	Write-Host "Passed:  $($results.PassedCount)" -ForegroundColor Green
	Write-Host "Failed:  $($results.FailedCount)" -ForegroundColor $(if ($results.FailedCount -gt 0) { 'Red' } else { 'Green' })
	Write-Host "Skipped: $($results.SkippedCount)" -ForegroundColor Yellow
	Write-Host "================================================`n" -ForegroundColor Cyan
	
	if ($results.FailedCount -gt 0) {
		exit 1
	}
}
catch {
	Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
	exit 1
}
finally {
	Stop-Transcript
	Write-Host "`nLog: $LogPath`n" -ForegroundColor Green
}
