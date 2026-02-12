Describe "New-rwDirPath" {
	BeforeAll {
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_AUTO', '1', 'Process')
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_SELECTION', '0', 'Process')

		$modulePath = Join-Path (Join-Path $PSScriptRoot '..') 'rwDirTools.psd1'
		Import-Module $modulePath -Force
	}

	BeforeEach {
		$testRoot = Join-Path $TestDrive "rwDirPathCreate_$(Get-Random)"
		if (Test-Path $testRoot) { Remove-Item $testRoot -Recurse -Force }
		New-Item -Path $testRoot -ItemType Directory | Out-Null
		Set-Variable -Name script:testRoot -Value $testRoot -Scope Script
	}

	AfterAll {
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_AUTO', '', 'Process')
		[System.Environment]::SetEnvironmentVariable('RW_DIRTOOLS_MENU_SELECTION', '', 'Process')
	}

	It "creates a folder and returns the full path" {
		$folder = "TestFolder_$(Get-Random)"
		$result = New-rwDirPath -Path $testRoot -DirName $folder -WarningAction SilentlyContinue
		Test-Path (Join-Path $testRoot $folder) | Should Be $true
		if ($result) { [System.IO.Path]::IsPathRooted($result) | Should Be $true }
	}

	It "can return DirectoryInfo when requested" {
		$folder = "ObjectFolder_$(Get-Random)"
		$result = New-rwDirPath -Path $testRoot -DirName $folder -Object -WarningAction SilentlyContinue
		if ($result) {
			$result | Should BeOfType System.IO.DirectoryInfo
			$result.Name | Should Be $folder
		}
	}

	It "does not recreate an existing folder" {
		$folder = "ExistsFolder"
		New-rwDirPath -Path $testRoot -DirName $folder | Out-Null
		(New-rwDirPath -Path $testRoot -DirName $folder -WarningAction SilentlyContinue) | Should BeNullOrEmpty
	}

	It "rejects invalid names" -Skip:([System.IO.Path]::GetInvalidFileNameChars() -contains '/') {
		(New-rwDirPath -Path $testRoot -DirName "Inva<>lid" -WarningAction SilentlyContinue) | Should BeNullOrEmpty
	}

	It "respects -WhatIf" {
		$folder = "WhatIf_$(Get-Random)"
		New-rwDirPath -Path $testRoot -DirName $folder -WhatIf -WarningAction SilentlyContinue | Out-Null
		Test-Path (Join-Path $testRoot $folder) | Should Be $false
	}

	It "returns array type even for single folder creation" {
		$folder = "ArrayTest_$(Get-Random)"
		$result = New-rwDirPath -Path $testRoot -DirName $folder -Object -Confirm:$false -WarningAction SilentlyContinue
		if ($result) {
			$result[0] | Should BeOfType System.IO.DirectoryInfo
			@($result).Count | Should Be 1
		}
	}
}
