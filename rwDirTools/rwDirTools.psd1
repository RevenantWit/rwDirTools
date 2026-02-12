@{
	RootModule = 'rwDirTools.psm1'
	ModuleVersion = '1.1.0'
	GUID = '00000000-0000-0000-0000-000000000000'
	Author = 'RevenantWit'
	CompanyName = ''
	Copyright = 'Copyright (c) 2026 RevenantWit. Licensed under MIT License.'
	Description = 'Utilities for selecting and creating directories with interactive and non-interactive modes.'
	PowerShellVersion = '5.1'
	
	FunctionsToExport = @(
		'Get-rwDirPath',
		'New-rwDirPath',
		'Out-rwMenuCLI'
	)
	CmdletsToExport = @()
	VariablesToExport = @()
	AliasesToExport = @()
	
	PrivateData = @{
		PSData = @{
			Tags = @('Directory', 'Menu', 'Interactive', 'CLI', 'GUI', 'Utility', 'Cross-Platform')
			LicenseUri = 'https://opensource.org/licenses/MIT'
			ProjectUri = 'https://github.com/RevenantWit/rwDirTools'
			ReleaseNotes = 'Refactored for less redundant and more modular code, and increased reliability'
		}
	}
}
