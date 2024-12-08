<#
.SYNOPSIS
  Disables the commands in the .draft folders for PowerStubs. This is disables 'developer mode'.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to Invoke-Authenticate.

.OUTPUTS

.EXAMPLES

#>


function Disable-PowerStubDraftCommands {
    Set-PowerStubConfigurationKey 'EnableFolder:Drafts', $false
}