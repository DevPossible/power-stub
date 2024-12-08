<#
.SYNOPSIS
  Gets the current full configuration

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS

.EXAMPLES

#>


function Get-PowerStubConfiguration {
    param (
        [string] $key
    )
    
    if ($key) {
        return $Script:PSTBSettings[$key]
    }
 
    return $Script:PSTBSettings
}