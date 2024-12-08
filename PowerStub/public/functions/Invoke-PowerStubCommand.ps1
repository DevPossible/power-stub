<#
.SYNOPSIS
  Creates a new PowerStub command in the specified PowerStub Collection.

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
        [string]$collection,
        [string]$command
    )
   
    Write-Host $myinvocation.line
}