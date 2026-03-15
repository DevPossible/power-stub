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
                    # Update git repos for stubs
                    # Usage: pstb update [stub] [--check]
                    #   --check: Only show status (fetch from remote) without pulling
                    if (-not $Script:GitEnabled) {
                        throw "Git integration is disabled. Enable it with: Set-PowerStubConfigurationKey 'GitEnabled' `$true"
                    }
                    if (-not $Script:GitAvailable) {
                        throw "Git is not available on this system."
                    }

                    # Parse arguments for --check flag and stub name
                    $checkOnly = $false
                    $targetStub = $null
                    $allArgs = @()
                    if ($command) { $allArgs += $command }
                    if ($RemainingArgs) { $allArgs += $RemainingArgs }

                    foreach ($arg in $allArgs) {
                        if ($arg -eq '--check' -or $arg -eq '-Check') {
                            $checkOnly = $true
                        }
                        elseif (-not $arg.StartsWith('-')) {
                            $targetStub = $arg
                        }
                    }

                    $stubs = Get-PowerStubConfigurationKey 'Stubs'
                    $processedRepos = @{}

                    if ($targetStub) {
                        # Process specific stub
                        if (-not ($stubs.Keys -contains $targetStub)) {
                            throw "Stub '$targetStub' not found."
                        }
                        $stubConfig = $stubs[$targetStub]
                        $stubPath = Get-PowerStubPath -StubConfig $stubConfig
                        $gitInfo = Get-PowerStubGitInfo -Path $stubPath -Fetch:$checkOnly
                        if (-not $gitInfo.IsRepo) {
                            throw "Stub '$targetStub' is not in a Git repository."
                        }

                        if ($checkOnly) {
                            # Show status only
                            if ($gitInfo.BehindCount -gt 0) {
                                Write-Host "Stub '$targetStub' is $($gitInfo.BehindCount) commit(s) behind." -ForegroundColor Yellow
                            }
                            elseif ($gitInfo.AheadCount -gt 0) {
                                Write-Host "Stub '$targetStub' is $($gitInfo.AheadCount) commit(s) ahead." -ForegroundColor Cyan
                            }
                            else {
                                Write-Host "Stub '$targetStub' is up to date." -ForegroundColor Green
                            }
                        }
                        else {
                            # Do actual update
                            Write-Host "Updating stub '$targetStub'..." -ForegroundColor Cyan
                            $result = Update-PowerStubGitRepo -Path $stubPath
                            if ($result.Success) {
                                Write-Host "  $($result.Message)" -ForegroundColor Green
                            }
                            else {
                                Write-Host "  $($result.Message)" -ForegroundColor Red
                            }
                        }
                    }
                    else {
                        # Process all stubs
                        $behindCount = 0
                        foreach ($stubName in $stubs.Keys) {
                            $stubConfig = $stubs[$stubName]
                            $stubPath = Get-PowerStubPath -StubConfig $stubConfig
                            $gitInfo = Get-PowerStubGitInfo -Path $stubPath -Fetch:$checkOnly
                            if ($gitInfo.IsRepo -and $gitInfo.RepoRoot -and -not $processedRepos.ContainsKey($gitInfo.RepoRoot)) {
                                if ($checkOnly) {
                                    # Show status only
                                    if ($gitInfo.BehindCount -gt 0) {
                                        Write-Host "Stub '$stubName' is $($gitInfo.BehindCount) commit(s) behind." -ForegroundColor Yellow
                                        $behindCount++
                                    }
                                    elseif ($gitInfo.AheadCount -gt 0) {
                                        Write-Host "Stub '$stubName' is $($gitInfo.AheadCount) commit(s) ahead." -ForegroundColor Cyan
                                    }
                                    else {
                                        Write-Host "Stub '$stubName' is up to date." -ForegroundColor Green
                                    }
                                }
                                else {
                                    # Do actual update
                                    Write-Host "Updating stub '$stubName' ($($gitInfo.RepoRoot))..." -ForegroundColor Cyan
                                    $result = Update-PowerStubGitRepo -Path $stubPath
                                    if ($result.Success) {
                                        Write-Host "  $($result.Message)" -ForegroundColor Green
                                    }
                                    else {
                                        Write-Host "  $($result.Message)" -ForegroundColor Red
                                    }
                                }
                                $processedRepos[$gitInfo.RepoRoot] = $true
                            }
                        }
                        if ($processedRepos.Count -eq 0) {
                            Write-Host "No stubs with Git repositories found." -ForegroundColor Yellow
                        }
                        elseif ($checkOnly) {
                            if ($behindCount -gt 0) {
                                Write-Host "`n$behindCount stub(s) have updates available. Run 'pstb update' to pull changes." -ForegroundColor Yellow
                            }
                            else {
                                Write-Host "`nAll $($processedRepos.Count) stub(s) are up to date." -ForegroundColor Green
                            }
                        }
                        else {
                            Write-Host "`nUpdated $($processedRepos.Count) repository(ies)." -ForegroundColor Cyan
                        }
                    }
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

        Write-Debug "Command path: $cmd"
        Write-Debug "Dynamic params: $($forwardParams.Keys -join ', ')"
        Write-Debug "Remaining args: $($RemainingArgs -join ', ')"

        Write-Host "Invoking $cmd"
        Invoke-CheckedCommandWithParams -command $cmd -namedParams $forwardParams -positionalArgs $RemainingArgs
    }
}