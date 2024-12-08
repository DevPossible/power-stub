<#
.SYNOPSIS
  Registers a new PowerStub in the specified path.

.DESCRIPTION
  Registers a new PowerStub in the specified path.
  
  A stub provides centralized access to a logical grouping of scripts or other tools.
  This facilitates proper organization and access to the scripts without requireing each element to be in the system path.
  
  Creates the folder and sub-folders, if necessary.

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS

.EXAMPLES

#>

function New-PowerStub {
    param(
        [string]$name,
        [string]$path,
        [switch]$force
    )
  
    #check to see if the path is already registered
    $stubs = Get-PowerStubConfigurationKey 'Stubs'
    if ($stubs.psobject.Properties.name -contains $name) {
        if ($force) {
            $stubs.$name = $path
        }
        else {
            throw "Stub $name already exists. Use -Force to overwrite."
        }
    }
    else {
        $stubs.$name = $path
    }
    
    #create the folder and standard child folders, if necessary  
    $paths = @($path, (Join-Path $path '.draft'), (Join-Path $path '.beta'), (Join-Path $path '.tests'), (Join-Path $path 'Commands'))
    foreach ($pathItem in $paths) {
        if (-not (Test-Path $pathItem)) {
            New-Item -ItemType Directory -Path $pathItem -Force | Out-Null
        }
    }
    
    #update the configuration
    Set-PowerStubConfigurationKey 'Stubs' $stubs
}


