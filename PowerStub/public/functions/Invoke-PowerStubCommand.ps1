<#
.SYNOPSIS
  Executes a stubbed element.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to Invoke-Authenticate.

.OUTPUTS

.EXAMPLES

#>

function Invoke-PowerStubCommand {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false, Position = 0)]
        [string] $stub,
        [parameter(Mandatory = $false, Position = 1)]
        [string] $command
    )

    if (!$command) {
        $stubs = Get-PowerStubConfiguration Stubs
        return $stubs.Keys
    }
   
    if (!$command) {
        Find-PowerStubCommands $stub
    }
    
    $line = $myinvocation.line
    Write-Host "line: $line"
    Write-Host "stub: $stub"
    Write-Host "command: $command"    
    
    $srch = "$stub $command"
    $i = $line.IndexOf($srch)
    $arguments = $line.Substring($i + $srch.Length).Trim()
        
    Write-Host "arguments: $arguments"
}