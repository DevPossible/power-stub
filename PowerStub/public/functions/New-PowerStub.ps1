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

    # Build stub configuration - either simple path or hashtable with git info
    $stubConfig = $path

    # Check for git repo if git is enabled
    if ($Script:GitEnabled) {
        $gitInfo = Get-PowerStubGitInfo -Path $path
        if ($gitInfo.IsRepo -and $gitInfo.RemoteUrl) {
            $stubConfig = @{
                Path       = $path
                GitRepoUrl = $gitInfo.RemoteUrl
            }
            Write-Verbose "Detected Git repository: $($gitInfo.RemoteUrl)"
        }
    }

    if ($stubs.Keys -contains $name) {
        if ($force) {
            $stubs[$name] = $stubConfig
        }
        else {
            throw "Stub $name already exists. Use -Force to overwrite."
        }
    }
    else {
        $stubs[$name] = $stubConfig
    }

    #create the folder and standard child folders, if necessary
    # Note: draft and beta commands use filename prefixes (draft.*, beta.*) instead of separate folders
    $paths = @($path, (Join-Path $path '.tests'), (Join-Path $path 'Commands'))
    foreach ($pathItem in $paths) {
        if (-not (Test-Path $pathItem)) {
            New-Item -ItemType Directory -Path $pathItem -Force | Out-Null
        }
    }

    #update the configuration
    Set-PowerStubConfigurationKey 'Stubs' $stubs
}


