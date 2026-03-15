<#
.SYNOPSIS
  Sets the whole configuration object and updates the config file.

.DESCRIPTION
  Replaces the current configuration with the provided hashtable, preserving
  internal keys (ModulePath, ConfigFile, etc.) that should not be overwritten.

.PARAMETER value
  The hashtable containing the new configuration values.

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS
None.
#>


function Set-PowerStubConfiguration {
    param (
        [HashTable] $value
    )

    # Preserve internal keys that should not be overwritten by external config
    $internalKeys = Get-PowerStubConfigurationKey 'InternalConfigKeys'
    if ($internalKeys) {
        foreach ($key in $internalKeys) {
            $currentVal = Get-PowerStubConfigurationKey $key
            if ($null -ne $currentVal -and -not $value.ContainsKey($key)) {
                $value[$key] = $currentVal
            }
        }
    }

    $Script:PSTBSettings = $value
    Export-PowerStubConfiguration
}
