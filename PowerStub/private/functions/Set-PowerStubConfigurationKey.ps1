<#
.SYNOPSIS
  Sets a configuration key and updates the config file.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS

.EXAMPLES

#>


function Set-PowerStubConfigurationKey {
    param (
        [string] $key,
        $value
    )
    
    $Script:PSTBSettings.$key = $value
    Export-PowerStubConfiguration    
}