# Test runner - Discover module location dynamically
param(
    [string]$LogPath
)

# Script is inside the module root - use directly
$moduleRoot = $PSScriptRoot
$testsDir = Join-Path $moduleRoot "Tests"

# Generate log path if not provided
if (-not $LogPath) {
    $LogPath = Join-Path $moduleRoot "TestResults_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
}

Write-Host "Starting tests at $(Get-Date)" -ForegroundColor Cyan
Write-Host "Module Root: $moduleRoot" -ForegroundColor Cyan
Write-Host "Tests Dir: $testsDir" -ForegroundColor Cyan
Write-Host "Log file: $LogPath" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

Start-Transcript -Path $LogPath -Force

try {
    # Safe module reload
    Remove-Module rwDirTools -Force -ErrorAction SilentlyContinue

    # Fresh import
    Write-Host "Importing rwDirTools..." -ForegroundColor Cyan
    Import-Module "$moduleRoot\rwDirTools.psd1" -Force
    Write-Host "Import complete`n" -ForegroundColor Green
    
    # Run all tests
    Write-Host "Running full test suite..." -ForegroundColor Cyan
    Write-Host "================================================`n" -ForegroundColor Cyan
    
    $results = Invoke-Pester -Path $testsDir -PassThru
    
    # Summary
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
