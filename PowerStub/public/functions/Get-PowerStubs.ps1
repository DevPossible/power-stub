<#
.SYNOPSIS
  Gets a list of all PowerStubs registered in the configuration.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS

.EXAMPLES

#>

function Get-PowerStubs {
    return (Get-PowerStubConfigurationKey 'Stubs')
}
