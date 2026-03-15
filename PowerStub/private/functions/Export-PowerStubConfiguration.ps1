<#
.SYNOPSIS
  Exports configuration to the configuration file.

.DESCRIPTION
  Serializes the current configuration (excluding internal keys) to JSON
  and writes it to the config file using atomic write (temp + rename).

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS
None.
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

    # Atomic write: write to temp file then rename to prevent corruption on concurrent access
    $tempFile = "$fileName.tmp"
    $exportConfig | ConvertTo-Json | Set-Content -Path $tempFile -Encoding UTF8
    Move-Item -Path $tempFile -Destination $fileName -Force
}
