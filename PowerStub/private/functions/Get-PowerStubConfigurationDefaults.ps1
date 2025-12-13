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
    
    $defaults = @{
        'ModulePath'         = $Script:ModulePath
        'ConfigFile'         = Join-Path $Script:ModulePath 'PowerStub.json'
        'InternalConfigKeys' = @('InternalConfigKeys', 'ModulePath', 'ConfigFile', 'GitAvailable')
        'InvokeAlias'        = 'pstb'
        'Stubs'              = @{}
        'EnablePrefix:Alpha' = $false
        'EnablePrefix:Beta'  = $false
        'GitEnabled'         = $true
        'GitAvailable'       = $false
    }
    
    return $defaults
}