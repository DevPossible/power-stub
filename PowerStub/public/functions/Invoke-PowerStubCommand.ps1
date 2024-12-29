<#
.SYNOPSIS
  Executes a stubbed element.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to Invoke-Authenticate.

.OUTPUTS

.EXAMPLES

#>

function Invoke-PowerStubCommand {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false, Position = 0)]
        [string] $stub,
        [parameter(Mandatory = $false, Position = 1)]
        [string] $command,
        [parameter(ValueFromRemainingArguments)]
        $arguments
    )

    DynamicParam {
        #result array
        $RuntimeParamDic = Get-PowerStubCommandDynamicParams $stub $command

        return $RuntimeParamDic
    }

    begin {
        Write-Debug "Begin"
    }

    process {
        Write-Debug "Process"
    }
}