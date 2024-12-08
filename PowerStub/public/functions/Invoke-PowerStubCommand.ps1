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
    param(
        [string]$stub,
        [string]$command
    )
   
    Write-Host $myinvocation.line
}