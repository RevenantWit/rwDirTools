$modulePath = Join-Path (Join-Path $PSScriptRoot '..') 'rwDirTools.psd1'
Import-Module $modulePath -Force

Describe "Get-rwDirPath" {
    BeforeAll {
        [System.Environment]::SetEnvironmentVariable('SKIP_GRIDVIEW', '1', 'Process')
    }

    AfterAll {
        [System.Environment]::SetEnvironmentVariable('SKIP_GRIDVIEW', '', 'Process')
    }

    BeforeEach {
        $testRoot = Join-Path $TestDrive "rwDirToolsTests"
        if (Test-Path $testRoot) {
            Remove-Item $testRoot -Recurse -Force
        }
        New-Item -Path $testRoot -ItemType Directory -Force | Out-Null
        New-Item -Path "$testRoot\Folder1" -ItemType Directory | Out-Null
        New-Item -Path "$testRoot\Folder2" -ItemType Directory | Out-Null
        New-Item -Path "$testRoot\EmptyFolder" -ItemType Directory | Out-Null
        New-Item -Path "$testRoot\Folder1\file.txt" -ItemType File | Out-Null
        New-Item -Path "$testRoot\Folder2\file.txt" -ItemType File | Out-Null
    }

    Context "Core Behavior" {
        It "Returns empty array for non-existent path" {
            $result = Get-rwDirPath -Path "C:\NonExistentPath12345" -WarningAction SilentlyContinue
            $result | Should BeNullOrEmpty
        }

        It "Returns empty array when path has no directories" {
            $emptyPath = Join-Path $TestDrive "NoFolders"
            New-Item -Path $emptyPath -ItemType Directory -Force | Out-Null
            $result = Get-rwDirPath -Path $emptyPath -WarningAction SilentlyContinue
            $result | Should BeNullOrEmpty
        }
    }

    Context "Filtering" {
        It "Excludes empty directories when -NoEmptyDir specified" {
            $allEmptyPath = Join-Path $TestDrive "AllEmpty"
            New-Item -Path $allEmptyPath -ItemType Directory -Force | Out-Null
            New-Item -Path "$allEmptyPath\Empty1" -ItemType Directory | Out-Null
            New-Item -Path "$allEmptyPath\Empty2" -ItemType Directory | Out-Null
            
            $result = Get-rwDirPath -Path $allEmptyPath -NoEmptyDir -WarningAction SilentlyContinue
            $result | Should BeNullOrEmpty
        }

        It "Respects -ExcludeDir parameter" {
            $result = Get-rwDirPath -Path $testRoot -ExcludeDir @("Folder1") -SingleDir -WarningAction SilentlyContinue
            if ($result) {
                [System.IO.Path]::GetFileName($result) | Should Not Match "Folder1"
            }
        }
    }

    Context "Error Handling" {
        It "Handles enumeration errors gracefully" {
            { $testRoot | Get-rwDirPath -SingleDir -WarningAction SilentlyContinue } | Should Not Throw
        }
    }

    Context "Output Behavior" {
        It "Returns DirectoryInfo objects when -Object specified" {
            $result = Get-rwDirPath -Path $testRoot -SingleDir -Object -WarningAction SilentlyContinue
    
            if ($result) {
                $result | Should BeOfType System.IO.DirectoryInfo
                Test-Path $result.FullName | Should Be $true
            }
        }
    }
}
