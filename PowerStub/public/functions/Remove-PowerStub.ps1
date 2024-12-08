<#
.SYNOPSIS
  Unregisters a PowerStub.

.DESCRIPTION
  Removes a PowerStub from the configuration, but does not remove any files.
  Can be re-added later.  

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS

.EXAMPLES

#>

function Remove-PowerStub {
    param(
        [string]$name
    )
    
    $stubs = Get-PowerStubConfigurationKey 'Stubs'
    if (-not $stubs.psobject.Properties.name -contains $name) {
        throw "Stub $name does not exist."
    }
    
    $stubs.Remove($name)
        
    #update the configuration
    Set-PowerStubConfigurationKey 'Stubs' $stubs
}
