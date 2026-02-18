function Show-rwPromptYesNo {
	[CmdletBinding()]

	param(
		[ValidateNotNullOrEmpty()]
		[string]$Title = "Please Confirm"
	)

	while ($true) {
		$resp = Read-Host "$Title (Y/N)"

		if ($resp -match '^[Yy]$') { 
			return $true 
		}
		if ($resp -match '^[Nn]$') {
			return $false 
		}
		Write-Host "Invalid input. Please enter Y or N." -ForegroundColor Yellow
	}
}
