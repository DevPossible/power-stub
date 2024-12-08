<#
.SYNOPSIS
  Finds all the commands for a stub while respecting the beta and draft settings.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS

.EXAMPLES

#>

function Find-PowerStubCommands {
    param(
        [string]$stub
    )
    $beta = Get-PowerStubConfigurationKey 'EnableFolder:Beta'
    $draft = Get-PowerStubConfigurationKey 'EnableFolder:Drafts'
    $stubs = Get-PowerStubConfigurationKey 'Stubs'
    $stubRoot = $stubs[$stub]
    
    $commands = Get-ChildItem -Path $stubRoot -Recurse -Include *.ps1
    if ($beta -eq $false) {
        $commands = $commands | Where-Object { $_.FullName -notmatch "\.beta" }
    }
    if ($draft -eq $false) {
        $commands = $commands | Where-Object { $_.FullName -notmatch "\.draft" }
    }
    return $commands
}