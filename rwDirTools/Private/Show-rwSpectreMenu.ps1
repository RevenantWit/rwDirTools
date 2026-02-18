function Show-rwSpectreMenu {
	param(
		[string]$Title,
		[string[]]$Options,
		[ValidateSet('Single','Multiple','YesNo')]
		[string]$OutputMode,
		[int]$DefaultSelection = -1
	)

	try {
		switch ($OutputMode) {
			'Single' {
				$prompt = [Spectre.Console.SelectionPrompt[string]]::new()
				$prompt.Title = "[cyan]$Title[/]"
				$prompt.PageSize = 15
				foreach ($opt in $Options) {
					[void]$prompt.AddChoice($opt)
				}
				if ($DefaultSelection -ge 0 -and $DefaultSelection -lt $Options.Count) {
					$prompt.DefaultValue = $Options[$DefaultSelection]
				}
				$result = [Spectre.Console.AnsiConsole]::Prompt($prompt)
				Write-Verbose "Spectre Single selection returned: $result"
				return $result
			}
			'Multiple' {
				$prompt = [Spectre.Console.MultiSelectionPrompt[string]]::new()
				$prompt.Title = "[cyan]$Title[/]"
				$prompt.PageSize = 15
				foreach ($opt in $Options) {
					[void]$prompt.AddChoice($opt)
				}
				$results = [Spectre.Console.AnsiConsole]::Prompt($prompt)
				Write-Verbose "Spectre Multiple selection returned: $($results.Count) items"
				return @($results)
			}
			'YesNo' {
				$result = [Spectre.Console.AnsiConsole]::Confirm("[cyan]$Title[/]", $true)
				Write-Verbose "Spectre YesNo returned: $result"
				return $result
			}
		}
	} catch {
		Write-Warning "Spectre rendering failed: $($_.Exception.Message). Returning null for fallback."
		Write-Verbose "Spectre error: $($_ | Out-String)"
		return $null
	}
}
