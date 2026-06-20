<#
.SYNOPSIS
  Gets a list of all registered PowerStubs.

.DESCRIPTION
  Returns a hashtable containing all PowerStubs registered in the current configuration.
  Each stub is a key with its configuration (path or hashtable with git info) as the value.

.INPUTS
  None. You cannot pipe objects to this function.

.OUTPUTS
  Hashtable containing stub names (keys) and their configuration values (paths or config objects).

.EXAMPLE
  Get-PowerStubs

  Returns all registered stubs and their paths.

.EXAMPLE
  Get-PowerStubs | ForEach-Object { $_.Keys }

  Lists only the stub names.

#>

function Get-PowerStubs {
    Sync-PowerStubConfiguration
    return (Get-PowerStubConfigurationKey 'Stubs')
}
