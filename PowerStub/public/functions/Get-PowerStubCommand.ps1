<#
.SYNOPSIS
  Gets the executable file or script file of the stub command

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS

.EXAMPLES

#>

function Get-PowerStubCommand {
    param(
        [string] $stub,
        [string] $command
    )
    $beta = Get-PowerStubConfigurationKey 'EnableFolder:Beta'
    $draft = Get-PowerStubConfigurationKey 'EnableFolder:Drafts'
    $stubs = Get-PowerStubConfigurationKey 'Stubs'
    $stubRoot = $stubs.$stub

    if (!$stubRoot) {
        Write-Warning "Stub '$stub' not found in the configuration."
        return
    }

    $includes = @("$($command).ps1", "$($command).exe")
    $commands = @(Get-ChildItem -Path $stubRoot -Recurse -Include $includes)
    if ($beta -eq $false) {
        $commands = @($commands | Where-Object { $_.FullName -notmatch "\.beta" })
    }
    if ($draft -eq $false) {
        $commands = @($commands | Where-Object { $_.FullName -notmatch "\.draft" })
    }

    $commandFile = $commands | Select-Object -First 1
    if (!$commandFile) {
        Write-Warning "Command '$command' not found in the stub '$stub'."
        return
    }
    $commandObj = Get-Command -Name $($commandFile.FullName) -ErrorAction SilentlyContinue
    return $commandObj
}