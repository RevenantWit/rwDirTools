# rwDirTools

Interactive directory selection and creation utilities for PowerShell.

## FEATURES

### Get-rwDirPath
- Select one or more directories interactively
- Automatic GUI/CLI fallback (Out-GridView, Spectre.Console, or CLI menu)
- Cross-platform support (Windows, Linux, Mac)
- Built-in filtering (-ExcludeDir, -NoEmptyDir)
- Returns full paths by default or names with -Name flag
- Returns DirectoryInfo objects with -Object flag
- Comprehensive error handling

### New-rwDirPath
- Create new directories with validation
- Interactive or non-interactive modes
- Windows reserved device name detection
- Invalid character validation
- Prevents duplicate folder creation
- Supports -WhatIf and -Confirm for safety

### Out-rwMenuCLI
- Unified CLI menu system
- Single selection, multiple selection, or yes/no modes
- Optional Spectre.Console enhancement
- Graceful fallback on errors
- Customizable titles and labels

## INSTALLATION

Copy rwDirTools folder to your PowerShell modules directory:
- Windows: C:\Users\YourUsername\Documents\PowerShell\Modules
- Linux/Mac: ~/.local/share/powershell/Modules

Or install with:
```powershell
	Import-Module path\to\rwDirTools
```

## USAGE

Select a folder
```powershell
	$folder = Get-rwDirPath -Path "C:\MyProjects" -SingleDir
```

Select multiple folders
```powershell
	$folders = Get-rwDirPath -Path "C:\MyProjects"
```

Create a new folder
```powershell
	$newFolder = New-rwDirPath -Path "C:\MyProjects" -DirName "NewProject"
```

Get folder object instead of string
```powershell
	$dirInfo = Get-rwDirPath -Path "C:\MyProjects" -Object
```

Scripted mode (no prompts)
```powershell
	$folder = Get-rwDirPath -Path "C:\MyProjects" -SingleDir

	$new = New-rwDirPath -Path "C:\MyProjects" -DirName "AutoFolder"
```

## TESTING

Run the test suite:
```powershell
	cd rwDirTools
	.\runTests-rwDirTools.ps1
```

All 20 tests should pass.

## REQUIREMENTS

- PowerShell 5.1 or later
- Optional: Spectre.Console module for enhanced CLI menus
  Install-Module Spectre.Console -Scope CurrentUser

## LICENSE

MIT License - See LICENSE file for details

## SUPPORT

Report issues at: https://github.com/RevenantWit/rwDirTools
