<#
.SYNOPSIS
  Disables alpha.* prefixed commands for PowerStubs. This disables 'developer mode'.

.DESCRIPTION
  When disabled, commands with the 'alpha.' prefix (e.g., alpha.my-command.ps1) are
  hidden from tab completion and cannot be executed.

.LINK

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS
None.

.EXAMPLES
  Disable-PowerStubAlphaCommands

#>


function Disable-PowerStubAlphaCommands {
    Set-PowerStubConfigurationKey 'EnablePrefix:Alpha' $false
}
