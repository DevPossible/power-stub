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
    $noExport = $Script:PSTBSettings['InternalConfigKeys']
    $fileName = $Script:PSTBSettings['ConfigFile']
    $exportConfig = @{}
    foreach ($key in $Script:PSTBSettings.Keys) {
        #do not export values for internal keys
        if ($noExport -contains $key) { continue }
        $exportConfig[$key] = $Script:PSTBSettings[$key] 
    }
    $exportConfig | ConvertTo-Json | Set-Content -Path $fileName -Encoding UTF8
}