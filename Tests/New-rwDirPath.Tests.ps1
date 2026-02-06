$modulePath = Join-Path (Join-Path $PSScriptRoot '..') 'rwDirTools.psd1'
Import-Module $modulePath -Force

Describe "New-rwDirPath" {
    BeforeEach {
        $testRoot = Join-Path $TestDrive "rwDirPathCreate_$(Get-Random)"
        if (Test-Path $testRoot) {
            Remove-Item $testRoot -Recurse -Force
        }
        New-Item -Path $testRoot -ItemType Directory -Force | Out-Null
    }

    Context "Core Behavior" {
        It "Creates folder and returns full path by default" {
            $folderName = "TestFolder_$(Get-Random)"
            $result = New-rwDirPath -Path $testRoot -DirName $folderName -ErrorAction SilentlyContinue
            
            Test-Path (Join-Path $testRoot $folderName) | Should Be $true
            if ($result) {
                [System.IO.Path]::IsPathRooted($result) | Should Be $true
            }
        }

        It "Returns folder name when -Name specified" {
            $folderName = "TestName_$(Get-Random)"
            $result = New-rwDirPath -Path $testRoot -DirName $folderName -Name -ErrorAction SilentlyContinue
            
            Test-Path (Join-Path $testRoot $folderName) | Should Be $true
            if ($result) {
                [System.IO.Path]::IsPathRooted($result) | Should Be $false
                $result | Should Be $folderName
            }
        }

        It "Returns null when folder already exists" {
            $folderName = "ExistingFolder"
            New-rwDirPath -Path $testRoot -DirName $folderName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
            $result = New-rwDirPath -Path $testRoot -DirName $folderName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            $result | Should BeNullOrEmpty
        }

        It "Returns DirectoryInfo object when -Object specified" {
            $folderName = "TestObject_$(Get-Random)"
            $result = New-rwDirPath -Path $testRoot -DirName $folderName -Object -ErrorAction SilentlyContinue
            
            Test-Path (Join-Path $testRoot $folderName) | Should Be $true
            if ($result) {
                $result | Should BeOfType System.IO.DirectoryInfo
                $result.Name | Should Be $folderName
            }
        }
    }

    Context "Validation" {
        It "Rejects invalid filename characters" -Skip:([System.Environment]::OSVersion.Platform -ne 'Win32NT') {
            $result = New-rwDirPath -Path $testRoot -DirName "Invalid<>Name" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            $result | Should BeNullOrEmpty
        }

        It "Rejects dot names" {
            $result = New-rwDirPath -Path $testRoot -DirName "." -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            $result | Should BeNullOrEmpty
        }

        It "Rejects reserved device names on Windows" -Skip:([System.Environment]::OSVersion.Platform -ne 'Win32NT') {
            $result = New-rwDirPath -Path $testRoot -DirName "CON" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            $result | Should BeNullOrEmpty
        }
    }

    Context "ShouldProcess" {
        It "Respects -WhatIf and does not create folder" {
            $folderName = "WhatIfTest_$(Get-Random)"
            $testFolder = Join-Path $testRoot $folderName
            New-rwDirPath -Path $testRoot -DirName $folderName -WhatIf -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
            Test-Path $testFolder | Should Be $false
        }
    }
}
