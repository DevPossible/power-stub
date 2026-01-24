<#
.SYNOPSIS
  Imports configuration from the configuration file in the module folder.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS

.EXAMPLES

#>


function Export-PowerStubConfiguration {
    $noExport = Get-PowerStubConfigurationKey 'InternalConfigKeys'
    $fileName = Get-PowerStubConfigurationKey 'ConfigFile'

    # Ensure config directory exists
    $configDir = Split-Path $fileName -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    $exportConfig = @{}
    foreach ($key in $Script:PSTBSettings.Keys) {
        #do not export values for internal keys
        if ($noExport -contains $key) { continue }
        $exportConfig[$key] = $Script:PSTBSettings[$key]
    }
    $exportConfig | ConvertTo-Json | Set-Content -Path $fileName -Encoding UTF8
}