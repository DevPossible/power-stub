#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from https://go.microsoft.com/fwlink/?LinkID=534084
#

$module = Get-Module -Name 'PowerStub'
if ($module) {
    Remove-Module -ModuleInfo $module -Force
}
$modulePath = Join-Path $PSScriptRoot '..\PowerStub\PowerStub.psm1'
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

        It "Should export on new stub" {
            $configFile = $config['ConfigFile']
            $configFileBackup = $config['ConfigFile'] + ".bak"

            if (Test-Path $configFile) {
                Copy-Item $configFile $configFileBackup -Force
                Remove-Item $configFile -Force
                Import-PowerStubConfiguration -reset
            }

            try {
                $testingPath = Join-Path $env:TEMP "PowerStubTesting"
                $(& New-PowerStub "PowerStubTesting" $testingPath) | Out-Null
                Test-Path $configFile | Should be $true
                
                $config = Get-PowerStubConfiguration
                $config.Stubs | Should Not Be $null
                $config.Stubs.Keys.Count | Should Be 1
            }
            finally {
                if (Test-Path $configFileBackup) {
                    Copy-Item $configFileBackup $configFile -Force
                    Remove-Item $configFileBackup -Force
                }
                Import-PowerStubConfiguration
            }
        }

    }

    Context "New-PowerStub" {
        BeforeAll {
            $configFile = $config['ConfigFile']
            $configFileBackup = $config['ConfigFile'] + ".bak"

            if (Test-Path $configFile) {
                Copy-Item $configFile $configFileBackup -Force
                Remove-Item $configFile -Force
                Import-PowerStubConfiguration -reset
            }
            $testingPath = Join-Path $env:TEMP "PowerStubTesting"
            if (Test-Path $testingPath) {
                Remove-Item $testingPath -Recurse -Force
            }
            New-Item -Path $testingPath -ItemType Directory | Out-Null
        }

        It "Should be a valid module export" {
            Get-Command -Module PowerStub -name 'Invoke-PowerStubCommand' | Should Not Be $null
        }

        It "Should export 'psb' alias" {
            $alias = Get-Alias -name $config['InvokeAlias']
            $alias | Should Not Be $null
            $alias.Definition | Should Be 'Invoke-PowerStubCommand'
        }

       
        AfterAll {
            if (Test-Path $configFileBackup) {
                Copy-Item $configFileBackup $configFile -Force
                Remove-Item $configFileBackup -Force
            }
            Import-PowerStubConfiguration
        }

    }
    
    Context "Management Functions" {
        It "Should be a valid module export" {
            Get-Command -Module PowerStub -name 'Invoke-PowerStubCommand' | Should Not Be $null
        }

        It "Should export 'psb' alias" {
            $alias = Get-Alias -name $config['InvokeAlias']
            $alias | Should Not Be $null
            $alias.Definition | Should Be 'Invoke-PowerStubCommand'
        }

    }


    
}