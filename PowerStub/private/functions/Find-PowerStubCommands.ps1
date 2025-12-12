<#
.SYNOPSIS
  Finds all the commands for a stub while respecting the alpha and beta prefix settings.

.DESCRIPTION
  Discovers all .ps1 and .exe files in a stub directory. Filters out commands with
  'alpha.' or 'beta.' prefixes unless those modes are enabled via configuration.

.LINK

.PARAMETER stub
  The name of the stub to search for commands.

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS
  FileInfo objects for each discovered command.

.EXAMPLES
  Find-PowerStubCommands -stub "DevOps"

#>

function Find-PowerStubCommands {
    param(
        [string]$stub
    )
    $alpha = Get-PowerStubConfigurationKey 'EnablePrefix:Alpha'
    $beta = Get-PowerStubConfigurationKey 'EnablePrefix:Beta'
    $stubs = Get-PowerStubConfigurationKey 'Stubs'
    $stubRoot = $stubs.$stub

    if (!$stubRoot) {
        Write-Warning "Stub '$stub' not found in the configuration."
        return
    }

    $commands = Get-ChildItem -Path $stubRoot -Recurse -Include *.ps1, *.exe

    # Filter out alpha-prefixed commands when alpha mode is not enabled
    if ($alpha -ne $true) {
        $commands = $commands | Where-Object { $_.BaseName -notmatch "^alpha\." }
    }

    # Filter out beta-prefixed commands when beta mode is not enabled
    if ($beta -ne $true) {
        $commands = $commands | Where-Object { $_.BaseName -notmatch "^beta\." }
    }

    return $commands
}