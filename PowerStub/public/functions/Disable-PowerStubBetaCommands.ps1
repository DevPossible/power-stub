<#
.SYNOPSIS
  Disables beta.* prefixed commands for PowerStubs. This disables 'beta-tester mode'.

.DESCRIPTION
  When disabled, commands with the 'beta.' prefix (e.g., beta.my-command.ps1) are
  hidden from tab completion and cannot be executed.

.LINK

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS
None.

.EXAMPLES
  Disable-PowerStubBetaCommands

#>


function Disable-PowerStubBetaCommands {
    Set-PowerStubConfigurationKey 'EnablePrefix:Beta' $false
}