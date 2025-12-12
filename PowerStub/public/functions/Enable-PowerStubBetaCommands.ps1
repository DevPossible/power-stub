<#
.SYNOPSIS
  Enables beta.* prefixed commands for PowerStubs. This is essentially 'beta-tester mode'.

.DESCRIPTION
  When enabled, commands with the 'beta.' prefix (e.g., beta.my-command.ps1) become
  visible in tab completion and can be executed.

.LINK

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS
None.

.EXAMPLES
  Enable-PowerStubBetaCommands

#>


function Enable-PowerStubBetaCommands {
    Set-PowerStubConfigurationKey 'EnablePrefix:Beta' $true
}