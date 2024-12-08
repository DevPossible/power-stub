<#
.SYNOPSIS
  Creates a new PowerStub command in the specified PowerStub Collection.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS

.EXAMPLES

#>

function New-PowerStubCommand {   
    param (
        [string]$collectionPath,
        [string]$name
    )
    
    if (-not (Test-Path $rootFolder)) {
        New-Item -ItemType Directory -Path $rootFolder
    }
}


