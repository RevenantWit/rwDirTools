# rwDirTools

Interactive directory selection and creation utilities for PowerShell.

## FEATURES

### Get-rwDirPath
- Select one or more directories interactively
- Automatic GUI/CLI fallback (Out-GridView, Spectre.Console, or CLI prompt)
- Cross-platform support (Windows, Linux, macOS)
- Built-in filtering (`-ExcludeDir`, `-NoEmptyDir`)
- Returns full paths by default, names with `-Name`, or DirectoryInfo with `-Object`
- Robust error handling with predictable output

### New-rwDirPath
- Creates directories with validation before touching the filesystem
- Interactive prompting or scripted via `-DirName`
- Detects Windows reserved device names and invalid characters
- Prevents duplicate folders and honors `-WhatIf`/`-Confirm`

### Out-rwMenuCLI
- Unified menu helper for single selection, multiple selection, and yes/no prompts
- Automatic Spectre.Console detection with graceful CLI fallback
- Custom titles and cancel labels

## INSTALLATION

Copy `rwDirTools` into your PowerShell module folder
- Windows: `C:\Users\YourUsername\Documents\PowerShell\Modules`
- Linux/macOS: `~/.local/share/powershell/Modules`

Or load directly
```powershell
	Import-Module path\to\rwDirTools
```

## USAGE (Windows Examples)

### Interactive Selection

Select a single folder
```powershell
	Get-rwDirPath -Path "C:\MyProjects" -SingleDir
```

Select multiple folders
```powershell
	Get-rwDirPath -Path "C:\MyProjects"
```

Get DirectoryInfo objects instead of paths
```powershell
	$dirs = Get-rwDirPath -Path "C:\MyProjects" -Object
	$dirs | ForEach-Object { "Size: $($_.LastAccessTime)" }
```

Get names only
```powershell
	Get-rwDirPath -Path "C:\MyProjects" -Name
```

### Directory Creation

Interactive mode (prompts for folder name):
```powershell
	New-rwDirPath -Path "C:\MyProjects"
```
Scripted mode (no prompts):
```powershell
	New-rwDirPath -Path "C:\MyProjects" -DirName "NewProject"
```
Get the created DirectoryInfo:
```powershell
	$newDir = New-rwDirPath -Path "C:\MyProjects" -DirName "NewProject" -Object
```
### Menus

Single selection:
```powershell
	$action = Out-rwMenuCLI -Title "Choose an action" -Options @('Start','Stop','Restart') -OutputMode Single
```
Multiple selection:
```powershell
	$items = Out-rwMenuCLI -Title "Pick items" -Options @('A','B','C') -OutputMode Multiple
```
Yes/No confirmation:
```powershell
	if (Out-rwMenuCLI -Title "Deploy now?" -OutputMode YesNo) {
		Write-Host "Deploying..."
	}
```
## AUTOMATION & TESTING

For non-interactive workflows or CI/CD:
```powershell
	# Enable automation mode
	$env:RW_DIRTOOLS_AUTO = '1'

	# Define menu selections (comma-separated zero-based indexes)
	$env:RW_DIRTOOLS_MENU_SELECTION = '0,2'

	# Define yes/no choice (1/true/yes or 0/false/no)
	$env:RW_DIRTOOLS_MENU_YESNO = '1'

	# Now interactive functions skip prompts and use env values
	Get-rwDirPath -Path "C:\MyProjects" -SingleDir
	Out-rwMenuCLI -Title "Pick" -Options @('A','B','C') -OutputMode Multiple
```
Run the test suite:
```powershell
	cd rwDirTools
	.\runTests-rwDirTools.ps1
```

## REQUIREMENTS

- PowerShell 5.1 or later
- Optional: Spectre.Console module for enhanced CLI menus  
  `Install-Module Spectre.Console -Scope CurrentUser`

## LICENSE

MIT License – See LICENSE file for details

## SUPPORT

Report issues at: https://github.com/RevenantWit/rwDirTools
