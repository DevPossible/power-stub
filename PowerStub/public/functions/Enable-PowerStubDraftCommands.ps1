<#
.SYNOPSIS
  Enables the commands in the .draft folders for PowerStubs. This is essentially 'developer mode'.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to Invoke-Authenticate.

.OUTPUTS

.EXAMPLES

#>


function Enable-PowerStubDraftCommands {
    Set-PowerStubConfigurationKey 'EnableFolder:Drafts', $true
}