function Get-rwDirFromUI {
	param(
		[string]$Title,
		[System.IO.DirectoryInfo[]]$Folders,
		[switch]$SingleDir,
		[switch]$RetryOnCancel,
		[int]$RetryAttempts = 3
	)

	$mode = if ($SingleDir) { 'Single' } else { 'Multiple' }
	Write-Verbose "Get-rwDirFromUI: Title='$Title' SingleDir=$SingleDir"

	for ($try = 0; $try -lt $RetryAttempts; $try++) {
		try {
			$selectedNames = if (Get-rwGridViewAvailable) {
				$Folders | Select-Object Name, FullName | Out-GridView -Title $Title -OutputMode $mode |
					ForEach-Object { $_.Name }
			} else {
				Out-rwMenuCLI -Title $Title -Options $Folders.Name -OutputMode $mode
			}
		} catch {
			Write-Verbose "UI attempt $($try + 1) failed: $($_.Exception.Message)"
			
			if ($try -eq $RetryAttempts - 1) {
				Write-Warning "UI interaction failed after $RetryAttempts attempts: $($_.Exception.Message)"
				return @()
			} else {
				Write-Warning "UI interaction failed: $($_.Exception.Message) (attempt $($try + 1)/$RetryAttempts)"
			}
			continue
		}

		if (-not $selectedNames) {
			if (-not $RetryOnCancel) { return @() }
			if ($try -eq $RetryAttempts - 1) { return @() }
			if (-not (Show-rwPromptYesNo -Title "No selection made. Try again?")) { return @() }
			continue
		}

		$selected = Ensure-rwArray ($Folders | Where-Object { $selectedNames -contains $_.Name })
		Write-Verbose "Selection complete: $($selected.Count) items selected"
		return $selected
	}

	return @()
}
