function Show-rwCLIMenu {
	param(
		[string]$Title,
		[string[]]$Options,
		[ValidateSet('Single','Multiple','YesNo')]
		[string]$OutputMode,
		[int]$DefaultSelection = -1,
		[string]$CancelLabel = 'Cancel'
	)

	switch ($OutputMode) {
		'Single'   { return Show-rwCLISingle   -Title $Title -Options $Options -DefaultSelection $DefaultSelection -CancelLabel $CancelLabel }
		'Multiple' { return Show-rwCLIMultiple -Title $Title -Options $Options -CancelLabel $CancelLabel }
		'YesNo'    { return Show-rwPromptYesNo -Title $Title }
		default    { throw "Unexpected OutputMode: $OutputMode" }
	}
}

function Show-rwCLISingle {
	param(
		[string]$Title,
		[string[]]$Options,
		[int]$DefaultSelection = -1,
		[string]$CancelLabel = 'Cancel'
	)

	$separator = '=' * 51
	while ($true) {
		if ($Host.UI.RawUI -and -not $env:CI) {
			try { Clear-Host } catch { Write-Verbose "Clear-Host failed" }
		}

		Write-Host $separator
		Write-Host " $Title"
		Write-Host $separator

		for ($i = 0; $i -lt $Options.Count; $i++) {
			$marker = if ($i -eq $DefaultSelection) { '*' }
			$display = $Options[$i] -replace '[\[\]]', '[$&]'
			Write-Host "[$($i+1)]$marker $display"
		}

		Write-Host "[Q] $CancelLabel"
		Write-Host $separator
		$input = Read-Host 'Choose an option'

		if ($input -match '^[Qq]$') {
			Write-Verbose "User cancelled single menu"
			return $null
		}

		if ($input -match '^\d+$') {
			$index = [int]$input - 1
			if ($index -ge 0 -and $index -lt $Options.Count) {
				Write-Verbose "User selected: $($Options[$index])"
				return $Options[$index]
			}
		}

		Write-Host "`nInvalid selection. Valid range: 1-$($Options.Count)" -ForegroundColor Yellow
		Write-Host 'Press Enter to try again.'
		Read-Host | Out-Null
	}
}

function Show-rwCLIMultiple {
	param(
		[string]$Title,
		[string[]]$Options,
		[string]$CancelLabel = 'Cancel'
	)

	$separator = '=' * 51
	while ($true) {
		if ($Host.UI.RawUI -and -not $env:CI) {
			try { Clear-Host } catch { Write-Verbose "Clear-Host failed" }
		}

		Write-Host $separator
		Write-Host " $Title"
		Write-Host $separator

		for ($i = 0; $i -lt $Options.Count; $i++) {
			$display = $Options[$i] -replace '[\[\]]', '[$&]'
			Write-Host "[$($i+1)] $display"
		}

		Write-Host "`nEnter numbers separated by commas (e.g., 1,3,5) or ranges (e.g., 1-3,5)"
		Write-Host "[Q] $CancelLabel"
		Write-Host $separator
		$input = Read-Host 'Selection'

		if ($input -match '^[Qq]$') {
			Write-Verbose "User cancelled multiple menu"
			return $null
		}

		$indexes = @()
		foreach ($part in ($input -split ',')) {
			$trim = $part.Trim()
			if ($trim -match '^(\d+)-(\d+)$') {
				$start = [int]$Matches[1] - 1
				$end = [int]$Matches[2] - 1
				if ($start -gt $end) { $temp = $start; $start = $end; $end = $temp }
				$indexes += $start..$end
			} elseif ($trim -match '^\d+$') {
				$indexes += [int]$trim - 1
			}
		}

		$validIndexes = @($indexes | Select-Object -Unique | Where-Object { $_ -ge 0 -and $_ -lt $Options.Count })
		$invalidIndexes = @($indexes | Where-Object { $_ -lt 0 -or $_ -ge $Options.Count })

		if ($validIndexes.Count -gt 0 -and $invalidIndexes.Count -eq 0) {
			$selected = @($validIndexes | ForEach-Object { $Options[$_] })
			Write-Verbose "User selected: @($($selected -join ','))"
			return $selected
		}

		if ($invalidIndexes.Count -gt 0) {
			Write-Host "`nInvalid selection(s). Valid range: 1-$($Options.Count)" -ForegroundColor Yellow
		} else {
			Write-Host "`nNo valid selections entered." -ForegroundColor Yellow
		}
		Write-Host 'Press Enter to try again, or Q to cancel.'
		Read-Host | Out-Null
	}
}
