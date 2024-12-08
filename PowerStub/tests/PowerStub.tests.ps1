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
    Context "Basic Functions" {
        It "Should be a valid module export" {
            Get-Command -Module PowerStub -name 'Invoke-PowerStubCommand' | Should Not Be $null
        }

        It "Should export 'psb' alias" {
            $alias = Get-Alias -name $config['InvokeAlias']
            $alias | Should Not Be $null
            $alias.Definition | Should Be 'Invoke-PowerStubCommand'
        }

        It "Should not Fail when called with no params" {
            $(& Invoke-PowerStubCommand)
        }
    }



}