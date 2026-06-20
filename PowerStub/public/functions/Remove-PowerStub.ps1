<#
.SYNOPSIS
  Unregisters a PowerStub from the configuration.

.DESCRIPTION
  Removes a PowerStub from the configuration, but does not delete any files or folders.
  The stub can be re-registered later with New-PowerStub. This only removes the stub
  from the registry; the actual command files remain on disk.

.PARAMETER Name
  The name of the stub to remove.

.INPUTS
  None. You cannot pipe objects to this function.

.OUTPUTS
  None. Updates the configuration by removing the stub.

.EXAMPLE
  Remove-PowerStub -Name "OldStub"

  Unregisters the "OldStub" stub while preserving its files.

.EXAMPLE
  Remove-PowerStub DevOps

  Removes the DevOps stub registration (positional parameter).

#>

function Remove-PowerStub {
    param(
        [string]$name
    )

    Sync-PowerStubConfiguration
    
    $stubs = Get-PowerStubConfigurationKey 'Stubs'
    if (-not $stubs.ContainsKey($name)) {
        throw "Stub $name does not exist."
    }
    
    $stubs.Remove($name)
        
    #update the configuration
    Set-PowerStubConfigurationKey 'Stubs' $stubs
}
