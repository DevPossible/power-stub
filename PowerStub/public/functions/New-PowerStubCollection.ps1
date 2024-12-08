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

function New-PowerStubCollection {
    param(
        [string]$name,
        [string]$path,
        [switch]$force
    )
  
    #check to see if the path is already registered
    if ($Script:PSTBSettings['Collections'].Keys -contains $name) {
        if ($force) {
            $Script:PSTBSettings['Collections'][$name] = $path
        }
        else {
            throw "Collection $name already exists. Use -Force to overwrite."
        }
    }
    else {
        $Script:PSTBSettings['Collections'][$name] = $path
    }
    
    #create the folder if necessary  
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path
    }
    
    #update the configuration
    Export-PowerStubConfiguration
}


