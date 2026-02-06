$modulePath = Join-Path (Join-Path $PSScriptRoot '..') 'rwDirTools.psd1'
Import-Module $modulePath -Force

Describe "Out-rwMenuCLI" {
    Context "Parameter Validation" {
        It "Throws error when Options is empty for Single mode" {
            { Out-rwMenuCLI -Title "Test" -Options @() -Mode Single } | Should Throw
        }

        It "Throws error when Options is empty for Multiple mode" {
            { Out-rwMenuCLI -Title "Test" -Options @() -Mode Multiple } | Should Throw
        }

        It "Does not require Options for YesNo mode" {
            $func = Get-Command Out-rwMenuCLI
            $func.Parameters['Options'].Attributes.Mandatory | Should Be $false
        }

        It "Rejects invalid Mode values" {
            { Out-rwMenuCLI -Title "Test" -Options @("A") -Mode "Invalid" } | Should Throw
        }

        It "Rejects out-of-range DefaultSelection" {
            { Out-rwMenuCLI -Title "Test" -Options @("A","B") -Mode Single -DefaultSelection 5 } | Should Throw
        }

        It "Rejects negative DefaultSelection except -1" {
            { Out-rwMenuCLI -Title "Test" -Options @("A","B") -Mode Single -DefaultSelection -2 } | Should Throw
        }
    }
}
