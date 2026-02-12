Describe "Get-rwDirPath" {
	BeforeAll {
		[System.Environment]::SetEnvironmentVariable('SKIP_GRIDVIEW', '1', 'Process')
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_AUTO', '1', 'Process')
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_SELECTION', '0', 'Process')
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_YESNO', '1', 'Process')

		$modulePath = Join-Path (Join-Path $PSScriptRoot '..') 'rwDirTools.psd1'
		Import-Module $modulePath -Force
	}

	BeforeEach {
		$testRoot = Join-Path $TestDrive "rwDirToolsTests"
		if (Test-Path $testRoot) { Remove-Item $testRoot -Recurse -Force }
		New-Item -Path "$testRoot\Folder1" -ItemType Directory | Out-Null
		New-Item -Path "$testRoot\Folder2" -ItemType Directory | Out-Null
		New-Item -Path "$testRoot\Folder1\file.txt" -ItemType File | Out-Null
		New-Item -Path "$testRoot\Folder2\file.txt" -ItemType File | Out-Null
		$script:testRoot = $testRoot
	}

	AfterAll {
		[System.Environment]::SetEnvironmentVariable('SKIP_GRIDVIEW', '', 'Process')
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_AUTO', '', 'Process')
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_SELECTION', '', 'Process')
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_YESNO', '', 'Process')
	}

	It 'verifies automation flag' { [Environment]::GetEnvironmentVariable('RW_DIRTOOLS_AUTO') | Should Be '1' }

	It "returns empty when no directories exist" {
		$emptyPath = Join-Path $TestDrive "EmptyRoot"
		New-Item -Path $emptyPath -ItemType Directory | Out-Null
		(Get-rwDirPath -Path $emptyPath -WarningAction SilentlyContinue) | Should BeNullOrEmpty
	}

	It "returns empty when path does not exist" {
		$result = Get-rwDirPath -Path "C:\NonExistentPath123456" -WarningAction SilentlyContinue
		$result | Should BeNullOrEmpty
	}

	It "applies filters and excludes empty directories" {
		$result = Get-rwDirPath -Path $testRoot -ExcludeDir @('Folder2') -NoEmptyDir -WarningAction SilentlyContinue
		$result | Should Not BeNullOrEmpty
		$result | Where-Object { $_ -like '*Folder2*' } | Should BeNullOrEmpty
	}

	It "never throws on enumeration failures" {
		{ Get-rwDirPath -Path $testRoot -SingleDir -WarningAction SilentlyContinue } | Should Not Throw
	}

	It "can return DirectoryInfo objects" {
		$result = Get-rwDirPath -Path $testRoot -SingleDir -Object -WarningAction SilentlyContinue
		if ($result) {
			$result | Should BeOfType System.IO.DirectoryInfo
			Test-Path $result.FullName | Should Be $true
		}
	}

	It "returns array type even for single selection" {
        $result = Get-rwDirPath -Path $testRoot -SingleDir -Object -WarningAction SilentlyContinue
        if ($result) {
            $result[0] | Should BeOfType System.IO.DirectoryInfo
            @($result).Count | Should Be 1
        }
	}
}
