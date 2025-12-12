<#
.SYNOPSIS
  Enables alpha.* prefixed commands for PowerStubs. This is essentially 'developer mode'.

.DESCRIPTION
  When enabled, commands with the 'alpha.' prefix (e.g., alpha.my-command.ps1) become
  visible in tab completion and can be executed.

.LINK

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS
None.

.EXAMPLES
  Enable-PowerStubAlphaCommands

#>


function Enable-PowerStubAlphaCommands {
    Set-PowerStubConfigurationKey 'EnablePrefix:Alpha', $true
}
