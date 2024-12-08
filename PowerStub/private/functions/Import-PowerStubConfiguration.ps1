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
    $noExport = $Script:PSTBSettings['InternalConfigKeys']
    $fileName = $Script:PSTBSettings['ConfigFile']
    $newConfig = Get-Content -Path $fileName -Raw | ConvertFrom-Json
    foreach ($key in $newConfig.Keys) {
        #do not import values for internal keys
        if ($noExport -contains $key) { continue }
        $Script:PSTBSettings[$key] = $newConfig[$key]    
    }
}