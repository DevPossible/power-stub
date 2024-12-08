<#
.SYNOPSIS
  Registers a new PowerStub Collection in the specified path.

.DESCRIPTION
  Registers a new PowerStub Collection in the specified path.
  
  Creates the folder if necessary.

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS

.EXAMPLES

#>

function Remove-PowerStubCollection {
    param(
        [string]$name
    )
    
    if (-not $Script:PSTBSettings['Collections'].Keys -contains $name) {
        throw "Collection $name does not exist."
    }
    
    $Script:PSTBSettings['Collections'].Remove($name)
        
    #update the configuration
    Export-PowerStubConfiguration
}
