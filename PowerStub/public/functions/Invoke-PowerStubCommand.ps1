<#
.SYNOPSIS
  Executes a command from a registered PowerStub.

.DESCRIPTION
  Invokes a command that is registered within a PowerStub stub. This is the main entry point
  for executing stubbed commands. It resolves the command path, forwards parameters and arguments,
  and executes the target script or executable with proper error handling and logging.

  Supports virtual verbs (search, help, update) that perform special operations without
  mapping to actual command files.

.PARAMETER Stub
  The name of the stub containing the command. Required unless using virtual verbs.
  Supports tab completion for registered stubs.

.PARAMETER Command
  The name of the command to execute within the stub. Required unless showing overview.
  Supports tab completion for commands in the selected stub.
  Supports dynamic parameters from the target command.

.PARAMETER RemainingArgs
  Arguments to pass to the target command. Captured from the command line and passed through unchanged.

.INPUTS
  None. You cannot pipe objects to this function.

.OUTPUTS
  Output from the executed command. This varies depending on the target command.

.EXAMPLE
  pstb DevOps deploy -Environment Production

  Executes the deploy command in the DevOps stub with the Environment parameter.

.EXAMPLE
  pstb search "backup"

  Searches all registered stubs for commands matching "backup".

.EXAMPLE
  pstb help DevOps deploy

  Displays PowerShell help for the deploy command in the DevOps stub.

.EXAMPLE
  pstb update --check

  Checks the status of all stub Git repositories without pulling changes.

#>

function Invoke-PowerStubCommand {
    [CmdletBinding()]
    param(
        [parameter(Position = 0)] [string] $stub,
        [parameter(Position = 1)] [string] $command,
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

        Sync-PowerStubConfiguration

        if (!$stub) {
            Show-PowerStubOverview
            return
        }

        # Virtual verb handling - these are reserved commands that don't map to script files
        $virtualVerbs = @('search', 'help', 'update')
        if ($virtualVerbs -contains $stub) {
            switch ($stub) {
                'search' {
                    if ($command) {
                        return Search-PowerStubCommands $command
                    }
                    else {
                        throw "Usage: pstb search <query>"
                    }
                }
                'help' {
                    if ($command -and $RemainingArgs -and $RemainingArgs.Count -gt 0) {
                        # pstb help <stub> <command>
                        return Get-PowerStubCommandHelp -Stub $command -Command $RemainingArgs[0]
                    }
                    elseif ($command) {
                        throw "Usage: pstb help <stub> <command>"
                    }
                    else {
                        throw "Usage: pstb help <stub> <command>"
                    }
                }
                'update' {
                    Invoke-PowerStubUpdate -Command $command -RemainingArgs $RemainingArgs
                    return
                }
            }
        }

        if (!$command) {
            Show-PowerStubCommands $stub
            return
        }

        # Check if stub is registered first
        $stubs = Get-PowerStubConfigurationKey 'Stubs'
        if (-not $stubs -or -not $stubs.ContainsKey($stub)) {
            $registeredStubs = if ($stubs) { ($stubs.Keys -join ', ') } else { '(none)' }
            Throw "Stub '$stub' is not registered. Registered stubs: $registeredStubs`n`nTo register: New-PowerStub -Name '$stub' -Path '<path-to-stub-folder>'"
        }

        $commandObj = Get-PowerStubCommand $stub $command
        if (!$commandObj) {
            $stubConfig = $stubs[$stub]
            $stubPath = Get-PowerStubPath -StubConfig $stubConfig
            Throw "Command '$command' not found in stub '$stub'.`n`nStub path: $stubPath`nExpected: $stubPath\Commands\$command.ps1 or $stubPath\Commands\$command\$command.ps1"
        }

        $cmd = $commandObj.Path

        # Collect dynamic parameters (bound params that aren't our static or common params)
        $forwardParams = @{}
        $skipParams = @('Stub', 'Command', 'RemainingArgs')
        $commonParamsList = @('Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction',
            'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer',
            'PipelineVariable', 'ProgressAction', 'WhatIf', 'Confirm')
        foreach ($key in $PSBoundParameters.Keys) {
            if ($key -notin $skipParams -and $key -notin $commonParamsList) {
                $forwardParams[$key] = $PSBoundParameters[$key]
            }
        }

        # Parse RemainingArgs to extract named parameters that match the target command.
        # This handles the case where callers use array splatting (& pstb @args) which
        # passes all elements as positional, preventing DynamicParam from capturing named params.
        $effectivePositionalArgs = @()
        if ($RemainingArgs -and $RemainingArgs.Count -gt 0) {
            $cmdParams = $commandObj.Parameters
            $i = 0
            while ($i -lt $RemainingArgs.Count) {
                $arg = $RemainingArgs[$i]
                if ($arg -is [string] -and $arg.StartsWith('-') -and $arg.Length -gt 1) {
                    $paramName = $arg.Substring(1)
                    if ($cmdParams.ContainsKey($paramName) -and -not $forwardParams.ContainsKey($paramName)) {
                        $paramType = $cmdParams[$paramName].ParameterType
                        if ($paramType -eq [System.Management.Automation.SwitchParameter]) {
                            $forwardParams[$paramName] = $true
                        }
                        else {
                            $i++
                            if ($i -lt $RemainingArgs.Count) {
                                $forwardParams[$paramName] = $RemainingArgs[$i]
                            }
                        }
                    }
                    else {
                        $effectivePositionalArgs += $arg
                    }
                }
                else {
                    $effectivePositionalArgs += $arg
                }
                $i++
            }
        }

        Write-Debug "Command path: $cmd"
        Write-Debug "Dynamic params: $($forwardParams.Keys -join ', ')"
        Write-Debug "Remaining args: $($effectivePositionalArgs -join ', ')"

        Write-Host "Invoking $cmd"
        Invoke-CheckedCommandWithParams -command $cmd -namedParams $forwardParams -positionalArgs $effectivePositionalArgs
    }
}
