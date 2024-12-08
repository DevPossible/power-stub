<#
.SYNOPSIS
  Gets a PowerStub configuration value by key.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS

.EXAMPLES

#>


function Get-PowerStubConfigurationKey {
    param (
        [string] $key
    )
    
    return $Script:PSTBSettings.$key
}