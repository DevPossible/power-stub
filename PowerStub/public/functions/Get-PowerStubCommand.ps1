<#
.SYNOPSIS
  Gets the executable file or script file of the stub command

.DESCRIPTION
  Locates and returns a PowerShell command object for the specified command in a stub.
  When alpha or beta modes are enabled, searches for prefixed versions with precedence:
  alpha.* -> beta.* -> unprefixed (production)

.LINK

.PARAMETER stub
  The name of the stub to search in.

.PARAMETER command
  The name of the command to find (without prefix).

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS
  A PowerShell command object for the found script or executable.

.EXAMPLES
  Get-PowerStubCommand -stub "DevOps" -command "deploy"

#>

function Get-PowerStubCommand {
    param(
        [string] $stub,
        [string] $command
    )
    $alpha = Get-PowerStubConfigurationKey 'EnablePrefix:Alpha'
    $beta = Get-PowerStubConfigurationKey 'EnablePrefix:Beta'
    $stubs = Get-PowerStubConfigurationKey 'Stubs'
    $stubRoot = $stubs.$stub

    if (!$stubRoot) {
        Write-Warning "Stub '$stub' not found in the configuration."
        return
    }

    $commandFile = $null

    # Precedence order: alpha -> beta -> production
    # 1. Try alpha-prefixed version first (if alpha enabled)
    if ($alpha -eq $true -and !$commandFile) {
        $alphaIncludes = @("alpha.$($command).ps1", "alpha.$($command).exe")
        $commandFile = Get-ChildItem -Path $stubRoot -Recurse -Include $alphaIncludes | Select-Object -First 1
    }

    # 2. Try beta-prefixed version (if beta enabled)
    if ($beta -eq $true -and !$commandFile) {
        $betaIncludes = @("beta.$($command).ps1", "beta.$($command).exe")
        $commandFile = Get-ChildItem -Path $stubRoot -Recurse -Include $betaIncludes | Select-Object -First 1
    }

    # 3. Try unprefixed (production) version
    if (!$commandFile) {
        $prodIncludes = @("$($command).ps1", "$($command).exe")
        $commandFile = Get-ChildItem -Path $stubRoot -Recurse -Include $prodIncludes | Select-Object -First 1
    }

    if (!$commandFile) {
        Write-Warning "Command '$command' not found in the stub '$stub'."
        return
    }

    $commandObj = Get-Command -Name $($commandFile.FullName) -ErrorAction SilentlyContinue
    return $commandObj
}