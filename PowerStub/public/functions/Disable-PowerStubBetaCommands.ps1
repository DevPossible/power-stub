<#
.SYNOPSIS
  Disables the commands in the .beta folders for PowerStubs. This is disables 'beta-tester mode'.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to Invoke-Authenticate.

.OUTPUTS

.EXAMPLES

#>


function Disable-PowerStubBetaCommands {
    Set-PowerStubConfigurationKey 'EnableFolder:Beta', $false
}