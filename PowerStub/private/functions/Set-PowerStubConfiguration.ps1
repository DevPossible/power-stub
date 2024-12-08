<#
.SYNOPSIS
  Sets the whole configuration object and updates the config file.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS

.EXAMPLES

#>


function Set-PowerStubConfiguration {
    param (
        [HashTable] $value
    )
    
    $Script:PSTBSettings = $value
    Export-PowerStubConfiguration
}