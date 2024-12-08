#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from https://go.microsoft.com/fwlink/?LinkID=534084
#

$module = Get-Module -Name 'PowerStub'
if ($module) {
    Remove-Module -ModuleInfo $module -Force
}
$modulePath = Join-Path $PSScriptRoot '..\PowerStub.psm1'
Import-Module $modulePath -Force -Verbose

$config = Get-PowerStubConfiguration

Describe "Execute-PowerStubCommand" {
    Context "Configuration" {
        It "Should be a valid module export" {
            Get-Command -Module PowerStub -name 'Get-PowerStubConfiguration' | Should Not Be $null
        }

        It "Should not Fail with no params" {
            $(& Get-PowerStubConfiguration) | Out-Null
        }

        It "Should not Fail with a key" {
            $(& Get-PowerStubConfiguration "ModulePath") | Out-Null
        }

        It "Should export on new collection" {
            $configFile = $config['ConfigFile']
            $configFileBackup = $config['ConfigFile'] + ".bak"

            if (Test-Path $configFile) {
                Copy-Item $configFile $configFileBackup -Force
                Remove-Item $configFile -Force
            }

            $testingPath = Join-Path $env:TEMP "PowerStubTesting"
            $(& New-PowerStubCollection "PowerStubTesting" $testingPath) | Out-Null
            Test-Path $configFile | Should be $true

            if (Test-Path $configFileBackup) {
                Copy-Item $configFileBackup $configFile -Force
                Remove-Item $configFileBackup -Force
            }
        }

    }

    Context "Basic Functions" {
        It "Should be a valid module export" {
            Get-Command -Module PowerStub -name 'Invoke-PowerStubCommand' | Should Not Be $null
        }

        It "Should export 'psb' alias" {
            $alias = Get-Alias -name $config['InvokeAlias']
            $alias | Should Not Be $null
            $alias.Definition | Should Be 'Invoke-PowerStubCommand'
        }

        It "Should not Fail with no params" {
            $(& Invoke-PowerStubCommand) | Out-Null
        }
    }

}