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


function Import-PowerStubConfiguration {
    param (
        [switch] $reset
    )

    if ($reset) {
        $Script:PSTBSettings = Get-PowerStubConfigurationDefaults
        Export-PowerStubConfiguration
        return
    }

    $noImport = Get-PowerStubConfigurationKey 'InternalConfigKeys'
    $fileName = Get-PowerStubConfigurationKey 'ConfigFile'
    $legacyFileName = Get-PowerStubConfigurationKey 'LegacyConfigFile'

    # Ensure config directory exists
    $configDir = Split-Path $fileName -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        Write-Verbose "Created config directory: $configDir"
    }

    Write-Verbose "Current Configuration:"
    Write-Verbose ($Script:PSTBSettings | ConvertTo-Json)

    # Check for config file, with migration from legacy location
    $configToLoad = $null
    if (Test-Path $fileName) {
        $configToLoad = $fileName
        Write-Verbose "Using config file: $fileName"
    }
    elseif ($legacyFileName -and (Test-Path $legacyFileName)) {
        # Migrate from legacy location (version-specific module folder)
        Write-Host "Migrating PowerStub config from legacy location..." -ForegroundColor Yellow
        Write-Verbose "Legacy config found at: $legacyFileName"
        Copy-Item -Path $legacyFileName -Destination $fileName -Force
        $configToLoad = $fileName
        Write-Host "  Config migrated to: $fileName" -ForegroundColor Green

        # Also check parent module folders for other version configs to migrate
        $moduleParent = Split-Path $Script:ModulePath -Parent
        $otherVersionConfigs = Get-ChildItem -Path $moduleParent -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne (Split-Path $Script:ModulePath -Leaf) } |
            ForEach-Object { Join-Path $_.FullName 'PowerStub.json' } |
            Where-Object { Test-Path $_ }

        if ($otherVersionConfigs) {
            Write-Verbose "Found configs in other module versions: $($otherVersionConfigs -join ', ')"
        }
    }

    if ($configToLoad) {
        Write-Verbose "Importing File: $configToLoad"
        $newConfig = Get-Content -Path $configToLoad -Raw | ConvertFrom-Json | ConvertTo-Hashtable
        foreach ($key in $newConfig.Keys) {
            #do not import values for internal keys
            if ($noImport -contains $key) { continue }
            Write-Verbose "Importing Configuration Key: $key"
            $Script:PSTBSettings[$key] = $newConfig[$key]
        }
    }
    else {
        Write-Verbose "No configuration file found. Using defaults."
    }

    Write-Verbose "New Configuration:"
    Write-Verbose ($Script:PSTBSettings | ConvertTo-Json)
}