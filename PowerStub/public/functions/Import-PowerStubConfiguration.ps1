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
    
    Write-Verbose "Current Configuration:"
    Write-Verbose ($Script:PSTBSettings | ConvertTo-Json)
    
    Write-Verbose "Importing File: $fileName"
    if (Test-Path $fileName) {
        $newConfig = Get-Content -Path $fileName -Raw | ConvertFrom-Json
        foreach ($key in $newConfig.psobject.Properties.name) {
            #do not import values for internal keys
            if ($noImport -contains $key) { continue }
            Write-Verbose "Importing Configuration Key: $key"
            $Script:PSTBSettings.$key = $newConfig.$key
        }
    }
    else {
        Write-Verbose "No configuration file found. Using defaults."
    }
    
    Write-Verbose "New Configuration:"
    Write-Verbose ($Script:PSTBSettings | ConvertTo-Json)
}