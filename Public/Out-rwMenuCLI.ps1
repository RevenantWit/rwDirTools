<#
.SYNOPSIS
Unified interactive prompt for single selection, multi-selection, and yes/no confirmation.

.DESCRIPTION
Out-rwMenuCLI provides interactive menus with automatic Spectre.Console detection. 
Falls back to CLI if Spectre is unavailable. Supports single/multi selection modes 
and yes/no confirmation.

.PARAMETER Title
Title or question displayed to the user. Default: "Options"

.PARAMETER Options
Array of menu options. Required for Single and Multiple modes.

.PARAMETER Mode
Prompt style: Single, Multiple, or YesNo. Default: Single

.PARAMETER DefaultSelection
Zero-based index of default option (Single mode only). Default: -1 (no default)

.PARAMETER CancelLabel
Cancel button label. Default: "Cancel"

.PARAMETER PreferredUI
UI preference: Auto (detect), Spectre (force), or CLI (force). Default: Auto

.EXAMPLE
$action = Out-rwMenuCLI -Title "Select Action" -Options @("Start","Stop","Restart") -Mode Single
# Single-selection menu, uses Spectre if available

.EXAMPLE
$modules = Out-rwMenuCLI -Title "Select Modules" -Options @("Mod1","Mod2","Mod3") -Mode Multiple
# Multi-selection menu, returns @("Mod1", "Mod3")

.EXAMPLE
$choice = Out-rwMenuCLI -Title "Main Menu" -Options @("Option1","Option2") -Mode Single -CancelLabel "Exit"
# Custom cancel label: [Q] Exit

.EXAMPLE
if (Out-rwMenuCLI -Title "Continue?" -Mode YesNo) { Write-Host "Proceeding..." }
# Yes/no confirmation prompt

.NOTES
Spectre.Console is optional. Install via: Install-Module Spectre.Console -Scope CurrentUser
#>
function Out-rwMenuCLI {
    [CmdletBinding()]
    [OutputType([string])]
    [OutputType([string[]])]
    [OutputType([bool])]
    param(
        [Parameter()]
        [string]$Title = 'Options',

        [Parameter()]
        [string[]]$Options,

        [Parameter()]
        [ValidateSet('Single', 'Multiple', 'YesNo')]
        [string]$Mode = 'Single',

        [Parameter()]
        [ValidateScript({
            if ($_ -eq -1) { return $true }
            if ($Mode -eq 'Single' -and $Options -and $_ -ge 0 -and $_ -lt $Options.Count) { return $true }
            throw "DefaultSelection must be -1 (no default) or a valid index within the Options array."
        })]
        [int]$DefaultSelection = -1,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$CancelLabel = "Cancel",
        
        [Parameter()]
        [ValidateSet('Auto', 'Spectre', 'CLI')]
        [string]$PreferredUI = 'Auto'
    )

    if ($Mode -in @('Single', 'Multiple')) {
        if (-not $Options -or $Options.Count -eq 0) {
            throw "Out-rwMenuCLI: Options array is required and cannot be empty for mode '$Mode'."
        }
        $Options = $Options | ForEach-Object { $_.ToString() }
    }

    $useUI = switch ($PreferredUI) {
        'Spectre' { 
            if (Test-SpectreAvailable) { 'Spectre' } else { 
                Write-Verbose "Spectre.Console requested but not available. Using CLI."
                'CLI' 
            } 
        }
        'CLI' { 'CLI' }
        'Auto' {
            if (Test-SpectreAvailable) { 'Spectre' } else { 'CLI' }
        }
    }

    Write-Verbose "Out-rwMenuCLI: Mode='$Mode', UI='$useUI', Title='$Title', Options count=$($Options.Count), DefaultSelection=$DefaultSelection, CancelLabel='$CancelLabel'"
    # Large list hint for CLI users
    if ($Options.Count -gt 19 -and $useUI -eq 'CLI' -and $Mode -in @('Single', 'Multiple')) {
        Write-Host ""
        Write-Host "💡 $($Options.Count) items detected. For better navigation:" -ForegroundColor Cyan
        Write-Host "   Install-Module Spectre.Console -Scope CurrentUser" -ForegroundColor Gray
        Write-Host ""
        Start-Sleep -Milliseconds 1500
    }

    # Dispatch to appropriate implementation
    if ($useUI -eq 'Spectre') {
        return Show-SpectreMenu -Title $Title -Options $Options -Mode $Mode -DefaultSelection $DefaultSelection -CancelLabel $CancelLabel
    } else {
        # Use reliable CLI fallback
        switch ($Mode) {
            'Single' {
                return _Show-rwMenuSingle -Title $Title -Options $Options -DefaultSelection $DefaultSelection -CancelLabel $CancelLabel
            }
            'Multiple' {
                return _Show-rwMenuMultiple -Title $Title -Options $Options -CancelLabel $CancelLabel
            }
            'YesNo' {
                return _Show-rwMenuYesNo -Title $Title
            }
        }
    }
}

function _Show-rwMenuSingle {
    [CmdletBinding()]
    param(
        [string]$Title,
        [string[]]$Options,
        [int]$DefaultSelection = -1,
        [string]$CancelLabel = "Cancel"
    )

    $menuSeparator = "=" * 51
    $cancelOption = "[Q] $CancelLabel"

    while ($true) {
        if ($Host.UI.RawUI -and -not $env:CI) {
            try {
                Clear-Host
            } catch {
                Write-Verbose "Clear-Host failed: $($_.Exception.Message). Skipping."
            }
        }

        Write-Host $menuSeparator
        Write-Host " $Title"
        Write-Host $menuSeparator

        for ($i = 0; $i -lt $Options.Count; $i++) {
            $marker = if ($i -eq $DefaultSelection) { "*" } else { " " }
            $displayOption = $Options[$i] -replace '[\[\]]', '[$&]'
            Write-Host "[$($i+1)]$marker $displayOption"
        }

        Write-Host $cancelOption
        Write-Host $menuSeparator
        $userInput = Read-Host "Choose an option"
        Write-Verbose "Single mode: User entered '$userInput'"

        if ($userInput -match '^[Qq]$') {
            Write-Verbose "User cancelled selection in Single mode"
            return $null
        }

        if ($userInput -match '^\d+$') {
            $index = [int]$userInput - 1
            if ($index -ge 0 -and $index -lt $Options.Count) {
                Write-Verbose "User selected option $($index + 1): '$($Options[$index])'"
                return $Options[$index]
            } else {
                Write-Verbose "Invalid index selected: $userInput"
                Write-Host "`nSelection out of range. Valid range: 1-$($Options.Count)" -ForegroundColor Yellow
            }
        } else {
            Write-Verbose "Invalid input format: '$userInput'"
            Write-Host "`nInvalid input. Please enter a number or Q to cancel." -ForegroundColor Yellow
        }
        
        Write-Host "Press Enter to try again."
        Read-Host | Out-Null
    }
}

function _Show-rwMenuMultiple {
    [CmdletBinding()]
    param(
        [string]$Title,
        [string[]]$Options,
        [string]$CancelLabel = "Cancel"
    )

    $menuSeparator = "=" * 51
    $cancelOption = "[Q] $CancelLabel"

    while ($true) {
        if ($Host.UI.RawUI -and -not $env:CI) {
            try {
                Clear-Host
            } catch {
                Write-Verbose "Clear-Host failed: $($_.Exception.Message). Skipping."
            }
        }

        Write-Host $menuSeparator
        Write-Host " $Title"
        Write-Host $menuSeparator

        for ($i = 0; $i -lt $Options.Count; $i++) {
            $displayOption = $Options[$i] -replace '[\[\]]', '[$&]'
            Write-Host "[$($i+1)] $displayOption"
        }

        Write-Host "`nEnter numbers separated by commas (e.g., 1,3,5) or ranges (e.g., 1-3,5)"
        Write-Host $cancelOption
        Write-Host $menuSeparator
        $userInput = Read-Host "Selection"
        Write-Verbose "Multiple mode: User entered '$userInput'"

        if ($userInput -match '^[Qq]$') {
            Write-Verbose "User cancelled selection in Multiple mode"
            return $null
        }

        $indices = @($userInput -split ',' | ForEach-Object {
            $part = $_.Trim()
            if ($part -match '^(\d+)-(\d+)$') {
                $start = [int]$Matches[1] - 1
                $end = [int]$Matches[2] - 1
                if ($start -le $end) {
                    Write-Verbose "Range expansion: $($Matches[1])-$($Matches[2]) -> indices $start..$end"
                    $start..$end
                } else {
                    Write-Verbose "Reversed range: $($Matches[1])-$($Matches[2]) -> flipped to $end..$start"
                    $end..$start
                }
            } elseif ($part -match '^\d+$') {
                [int]$part - 1
            }
        })

        $indices = @($indices | Select-Object -Unique | Sort-Object)
        $invalidIndices = @($indices | Where-Object { $_ -lt 0 -or $_ -ge $Options.Count })
        
        if ($indices.Count -gt 0 -and $invalidIndices.Count -eq 0) {
            $selectedItems = @($indices | ForEach-Object { $Options[$_] })
            Write-Verbose "User selected $($selectedItems.Count) item(s) in Multiple mode: $($selectedItems -join ', ')"
            return $selectedItems
        }

        if ($invalidIndices.Count -gt 0) {
            Write-Verbose "Invalid indices detected: $($invalidIndices -join ',')"
            Write-Host "`nInvalid selection(s) detected. Valid range: 1-$($Options.Count)" -ForegroundColor Yellow
        } else {
            Write-Verbose "No valid selections entered"
            Write-Host "`nNo valid selections entered." -ForegroundColor Yellow
        }
        Write-Host "Press Enter to try again, or Q to cancel."
        Read-Host | Out-Null
    }
}

function _Show-rwMenuYesNo {
    [CmdletBinding()]
    param(
        [string]$Title
    )

    while ($true) {
        $resp = Read-Host "$Title (Y/N)"
        Write-Verbose "YesNo mode: User entered '$resp'"

        if ($resp -match '^[Yy]$') { 
            Write-Verbose "User selected: Yes"
            return $true 
        }
        if ($resp -match '^[Nn]$') { 
            Write-Verbose "User selected: No"
            return $false 
        }

        Write-Verbose "Invalid YesNo response: '$resp'"
        Write-Host "Invalid input. Please enter Y or N." -ForegroundColor Yellow
    }
}

function Test-SpectreAvailable {
    try {
        $module = Get-Module -Name Spectre.Console -ListAvailable -ErrorAction Stop
        if ($module) {
            Import-Module Spectre.Console -ErrorAction Stop -WarningAction SilentlyContinue
            Write-Verbose "Spectre.Console detected (version $($module.Version))"
            return $true
        }
    } catch {
        Write-Verbose "Spectre.Console not available: $($_.Exception.Message)"
    }
    return $false
}

function Show-SpectreMenu {
    [CmdletBinding()]
    param(
        [string]$Title,
        [string[]]$Options,
        [string]$Mode,
        [int]$DefaultSelection = -1,
        [string]$CancelLabel = "Cancel"
    )

    try {
        switch ($Mode) {
            'Single' {
                $prompt = [Spectre.Console.SelectionPrompt[string]]::new()
                $prompt.Title = "[cyan]$Title[/]"
                $prompt.PageSize = 15
                $prompt.MoreChoicesText = "[grey](Move up and down to reveal more options)[/]"
                $prompt.HighlightStyle = [Spectre.Console.Style]::new([Spectre.Console.Color]::Cyan)
                
                foreach ($opt in $Options) {
                    [void]$prompt.AddChoice($opt)
                }
                
                if ($DefaultSelection -ge 0 -and $DefaultSelection -lt $Options.Count) {
                    $prompt.DefaultValue = $Options[$DefaultSelection]
                }
                
                Write-Verbose "Displaying Spectre single-selection menu"
                $result = [Spectre.Console.AnsiConsole]::Prompt($prompt)
                Write-Verbose "Spectre menu: User selected '$result'"
                return $result
            }
            
            'Multiple' {
                $prompt = [Spectre.Console.MultiSelectionPrompt[string]]::new()
                $prompt.Title = "[cyan]$Title[/]"
                $prompt.PageSize = 15
                $prompt.MoreChoicesText = "[grey](Move up and down to reveal more options)[/]"
                $prompt.InstructionsText = "[grey](Press [blue]<space>[/] to toggle, [green]<enter>[/] to accept)[/]"
                $prompt.Required = $false
                
                foreach ($opt in $Options) {
                    [void]$prompt.AddChoice($opt)
                }
                
                Write-Verbose "Displaying Spectre multi-selection menu"
                $results = [Spectre.Console.AnsiConsole]::Prompt($prompt)
                
                if ($results.Count -eq 0) {
                    Write-Verbose "Spectre multi-menu: No selections (user cancelled)"
                    return $null
                }
                
                Write-Verbose "Spectre multi-menu: User selected $($results.Count) item(s)"
                return @($results)
            }
            
            'YesNo' {
                Write-Verbose "Displaying Spectre confirmation prompt"
                $result = [Spectre.Console.AnsiConsole]::Confirm("[cyan]$Title[/]", $true)
                Write-Verbose "Spectre YesNo: User selected $result"
                return $result
            }
        }
    } catch {
        Write-Warning "Spectre.Console rendering failed: $($_.Exception.Message). Falling back to CLI."
        Write-Verbose "Spectre error details: $($_ | Out-String)"
        
        # Fallback to CLI on any error
        switch ($Mode) {
            'Single' { return _Show-rwMenuSingle -Title $Title -Options $Options -DefaultSelection $DefaultSelection -CancelLabel $CancelLabel }
            'Multiple' { return _Show-rwMenuMultiple -Title $Title -Options $Options -CancelLabel $CancelLabel }
            'YesNo' { return _Show-rwMenuYesNo -Title $Title }
        }
    }
}
