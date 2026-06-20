<#
.SYNOPSIS
  Gets the current PowerStub configuration.

.DESCRIPTION
  Returns the entire configuration hashtable, or optionally returns a single configuration key.
  The configuration contains all registered stubs, prefixes enabled/disabled status, and other settings.

.PARAMETER Key
  Optional. The name of a specific configuration key to retrieve. If not specified, returns the entire configuration.

.INPUTS
  None. You cannot pipe objects to this function.

.OUTPUTS
  Hashtable containing the entire configuration, or a scalar value if a specific key is requested.

.EXAMPLE
  Get-PowerStubConfiguration

  Returns the entire configuration hashtable.

.EXAMPLE
  Get-PowerStubConfiguration -Key "Stubs"

  Returns only the Stubs configuration containing all registered stubs.

.EXAMPLE
  Get-PowerStubConfiguration | ConvertTo-Json

  Displays the configuration formatted as JSON.

#>


function Get-PowerStubConfiguration {
    param (
        [string] $key
    )

    Sync-PowerStubConfiguration
    
    if ($key) {
        return $Script:PSTBSettings[$key]
    }
 
    return $Script:PSTBSettings
}
