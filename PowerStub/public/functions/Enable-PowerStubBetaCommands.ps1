<#
.SYNOPSIS
  Enables the commands in the .beta folders for PowerStubs. This is essentially 'beta-tester mode'.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to Invoke-Authenticate.

.OUTPUTS

.EXAMPLES

#>


function Enable-PowerStubBetaCommands {
    Set-PowerStubConfigurationKey 'EnableFolder:Beta', $true
}