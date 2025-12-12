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
        [parameter(DontShow = $true, Mandatory = $False, Position = 2)] [object] $o1,
        [parameter(DontShow = $true, Mandatory = $False, Position = 3)] [object] $o2,
        [parameter(DontShow = $true, Mandatory = $False, Position = 4)] [object] $o3,
        [parameter(DontShow = $true, Mandatory = $False, Position = 5)] [object] $o4,
        [parameter(DontShow = $true, Mandatory = $False, Position = 6)] [object] $o5,
        [parameter(DontShow = $true, Mandatory = $False, Position = 7)] [object] $o6,
        [parameter(DontShow = $true, Mandatory = $False, Position = 8)] [object] $o7,
        [parameter(DontShow = $true, Mandatory = $False, Position = 9)] [object] $o8,
        [parameter(DontShow = $true, Mandatory = $False, Position = 10)] [object] $o9,
        [parameter(DontShow = $true, Mandatory = $False, Position = 11)] [object] $o10,
        [parameter(DontShow = $true, Mandatory = $False, Position = 12)] [object] $o11,
        [parameter(DontShow = $true, Mandatory = $False, Position = 13)] [object] $o12,
        [parameter(DontShow = $true, Mandatory = $False, Position = 14)] [object] $o13,
        [parameter(DontShow = $true, Mandatory = $False, Position = 15)] [object] $o14,
        [parameter(DontShow = $true, Mandatory = $False, Position = 16)] [object] $o15,
        [parameter(DontShow = $true, Mandatory = $False, Position = 17)] [object] $o16,
        [parameter(DontShow = $true, Mandatory = $False, Position = 18)] [object] $o17,
        [parameter(DontShow = $true, Mandatory = $False, Position = 19)] [object] $o18,
        [parameter(DontShow = $true, Mandatory = $False, Position = 20)] [object] $o19,
        [parameter(DontShow = $true, Mandatory = $False, Position = 21)] [object] $o20,
        [parameter(DontShow = $true, Mandatory = $False, Position = 22)] [object] $o21,
        [parameter(DontShow = $true, Mandatory = $False, Position = 23)] [object] $o22,
        [parameter(DontShow = $true, Mandatory = $False, Position = 24)] [object] $o23,
        [parameter(DontShow = $true, Mandatory = $False, Position = 25)] [object] $o24,
        [parameter(DontShow = $true, Mandatory = $False, Position = 26)] [object] $o25,
        [parameter(DontShow = $true, Mandatory = $False, Position = 27)] [object] $o26,
        [parameter(DontShow = $true, Mandatory = $False, Position = 28)] [object] $o27,
        [parameter(DontShow = $true, Mandatory = $False, Position = 29)] [object] $o28,
        [parameter(DontShow = $true, Mandatory = $False, Position = 30)] [object] $o29,
        [parameter(DontShow = $true, Mandatory = $False, Position = 31)] [object] $o30,
        [parameter(DontShow = $true, Mandatory = $False, Position = 32)] [object] $o31,
        [parameter(DontShow = $true, Mandatory = $False, Position = 33)] [object] $o32,
        [parameter(DontShow = $true, Mandatory = $False, Position = 34)] [object] $o33,
        [parameter(DontShow = $true, Mandatory = $False, Position = 35)] [object] $o34,
        [parameter(DontShow = $true, Mandatory = $False, Position = 36)] [object] $o35,
        [parameter(DontShow = $true, Mandatory = $False, Position = 37)] [object] $o36,
        [parameter(DontShow = $true, Mandatory = $False, Position = 38)] [object] $o37,
        [parameter(DontShow = $true, Mandatory = $False, Position = 39)] [object] $o38,
        [parameter(DontShow = $true, Mandatory = $False, Position = 40)] [object] $o39,
        [parameter(DontShow = $true, Mandatory = $False, Position = 41)] [object] $o40

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
        $cmdArgs = $line.Substring($i + $srch.Length).Trim()

        $cmd = $commandObj.Path

        if ($cmdArgs) {
            Write-Host "Invoking $cmd with arguments: $cmdArgs"
            invoke-CheckedCommandWithParams $cmd $null $cmdArgs $true
        }
        else {
            Write-Host "Invoking $cmd"
            $myArgArray = $PSBoundParameters | Where-Object { $_.Key -like 'o*' } | Select-Object -ExpandProperty Value
            Write-Host "Arguments: $args"
            invoke-CheckedCommandWithParams $cmd $myArgArray $null $true
        }
    }
}