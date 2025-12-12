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
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true, Position = 0)] [string] $stub,
        [parameter(Mandatory = $true, Position = 1)] [string] $command,
        # ValueFromRemainingArguments captures any positional arguments after stub and command
        [parameter(DontShow = $true, ValueFromRemainingArguments = $true)] [object[]] $RemainingArgs
    )

    DynamicParam {
        # Get stub and command from PSBoundParameters (not variables - they don't exist yet during DynamicParam)
        $stubValue = $PSBoundParameters['Stub']
        $commandValue = $PSBoundParameters['Command']

        # Only build dynamic params if both stub and command are provided
        if ($stubValue -and $commandValue) {
            $RuntimeParamDic = Get-PowerStubCommandDynamicParams $stubValue $commandValue
            return $RuntimeParamDic
        }

        # Return empty dictionary if we don't have both values yet
        return New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
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
        $cmdArgs = $line.Substring($i + $srch.Length).Trim()

        $cmd = $commandObj.Path

        if ($cmdArgs) {
            Write-Host "Invoking $cmd with arguments: $cmdArgs"
            invoke-CheckedCommandWithParams $cmd $null $cmdArgs $true
        }
        elseif ($RemainingArgs -and $RemainingArgs.Count -gt 0) {
            Write-Host "Invoking $cmd with positional arguments"
            invoke-CheckedCommandWithParams $cmd $RemainingArgs $null $true
        }
        else {
            Write-Host "Invoking $cmd"
            invoke-CheckedCommandWithParams $cmd $null $null $true
        }
    }
}