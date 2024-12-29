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
        Write-Debug "Invoke-PowerStubCommand Begin"
    }

    process {
        Write-Debug "Invoke-PowerStubCommand Process"
    }

    end {
        Write-Debug "Invoke-PowerStubCommand Process"

        if (!$stub) {
            $stubs = Get-PowerStubConfiguration Stubs
            return $stubs.Keys
        }

        if (!$command) {
            Find-PowerStubCommands $stub
        }

        $commandObj = Get-PowerStubCommand $stub $command
        if (!$commandObj) {
            Throw "Command '$stub : $command' not found!"
        }

        $line = $myinvocation.line
        Write-Debug "line: $line"
        Write-Debug "stub: $stub"
        Write-Debug "command: $command"

        $srch = "$stub $command"
        $i = $line.IndexOf($srch)
        $arguments = $line.Substring($i + $srch.Length).Trim()

        $executable = $commandObj.Path
        $expression = "& '$executable' $arguments"
        Write-Debug "Executing Expression: $expression"
        Invoke-Expression $expression
    }
}