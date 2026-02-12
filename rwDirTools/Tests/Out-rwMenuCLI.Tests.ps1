Describe "Out-rwMenuCLI" {
	BeforeAll {
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_AUTO', '1', 'Process')
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_SELECTION', '0', 'Process')
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_YESNO', '1', 'Process')

		$modulePath = Join-Path (Join-Path $PSScriptRoot '..') 'rwDirTools.psd1'
		Import-Module $modulePath -Force
	}

	AfterAll {
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_AUTO', '', 'Process')
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_SELECTION', '', 'Process')
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_YESNO', '', 'Process')
	}

	It 'verifies automation flag' { 
		[Environment]::GetEnvironmentVariable('RW_DIRTOOLS_AUTO') | Should Be '1' 
	}

	It "throws when Options is missing or empty for selection modes" {
		{ Out-rwMenuCLI -Title 'Test' -Options @() -OutputMode Single } | Should Throw
		{ Out-rwMenuCLI -Title 'Test' -Options @() -OutputMode Multiple } | Should Throw
	}

	It "returns boolean for YesNo mode" {
		$result = Out-rwMenuCLI -Title 'Confirm?' -OutputMode YesNo
		$result | Should BeOfType System.Boolean
		$result | Should Be $true
	}

	It "rejects invalid default selection values" {
		{ Out-rwMenuCLI -Title 'Test' -Options @('A','B') -OutputMode Single -DefaultSelection 5 } | Should Throw
		{ Out-rwMenuCLI -Title 'Test' -Options @('A','B') -OutputMode Single -DefaultSelection -2 } | Should Throw
	}

	It "returns selected values in automation mode" {
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_SELECTION', '1,0', 'Process')
		$result = Out-rwMenuCLI -Title 'Pick' -Options @('A','B','C') -OutputMode Multiple
		$result | Should BeExactly @('B','A')
	}

	It "uses default selection when no automation value is provided" {
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_SELECTION', '', 'Process')
		$result = Out-rwMenuCLI -Title 'Pick' -Options @('A','B','C') -OutputMode Single -DefaultSelection 2
		$result | Should Be 'C'
	}

	It "handles nested menu calls" {
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_SELECTION', '0', 'Process')
		$result1 = Out-rwMenuCLI -Options @('A','B') -OutputMode Single
		$result2 = Out-rwMenuCLI -Options @('X','Y','Z') -OutputMode Single
		$result1 | Should Be 'A'
		$result2 | Should Be 'X'
	}
}
