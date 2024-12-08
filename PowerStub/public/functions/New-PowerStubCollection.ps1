<#
.SYNOPSIS
  Registers a new PowerStub Collection in the specified path.

.DESCRIPTION
  Registers a new PowerStub Collection in the specified path.
  
  Creates the folder if necessary.

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to Invoke-Authenticate.

.OUTPUTS

.EXAMPLES

#>

function New-PowerStubCollection {
    param(
        [string]$path
    )
  
    #check to see if the path is already registered
  
  
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path
    }
}


