<#
.SYNOPSIS
  Gets an instance of the configuration with default values.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS

.EXAMPLES

#>


function Get-PowerStubConfigurationDefaults {

    # Use version-independent config path to persist across module updates
    $configDir = if ($env:APPDATA) {
        Join-Path $env:APPDATA 'PowerStub'
    } else {
        Join-Path $HOME '.config/powerstub'
    }

    $defaults = @{
        'ModulePath'         = $Script:ModulePath
        'ConfigFile'         = Join-Path $configDir 'config.json'
        'LegacyConfigFile'   = Join-Path $Script:ModulePath 'PowerStub.json'
        'InternalConfigKeys' = @('InternalConfigKeys', 'ModulePath', 'ConfigFile', 'LegacyConfigFile', 'GitAvailable')
        'InvokeAlias'        = 'pstb'
        'Stubs'              = @{}
        'EnablePrefix:Alpha' = $false
        'EnablePrefix:Beta'  = $false
        'GitEnabled'         = $true
        'GitAvailable'       = $false
    }

    return $defaults
}