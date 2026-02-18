@{
	RootModule = 'rwDirTools.psm1'
	ModuleVersion = '1.1.1'
	GUID = '44e4c0c5-4b22-4696-b1b5-76baef37c281'
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
			ReleaseNotes = 'Small fix for -ExcludeDir to support widcard matching.'
		}
	}
}
