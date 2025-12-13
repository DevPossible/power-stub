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
                    if (-not $Script:GitEnabled) {
                        throw "Git integration is disabled. Enable it with: Set-PowerStubConfigurationKey 'GitEnabled' `$true"
                    }
                    if (-not $Script:GitAvailable) {
                        throw "Git is not available on this system."
                    }

                    $stubs = Get-PowerStubConfigurationKey 'Stubs'
                    $updatedRepos = @{}

                    if ($command) {
                        # Update specific stub
                        if (-not ($stubs.Keys -contains $command)) {
                            throw "Stub '$command' not found."
                        }
                        $stubConfig = $stubs[$command]
                        $stubPath = Get-PowerStubPath -StubConfig $stubConfig
                        $gitInfo = Get-PowerStubGitInfo -Path $stubPath
                        if (-not $gitInfo.IsRepo) {
                            throw "Stub '$command' is not in a Git repository."
                        }
                        Write-Host "Updating stub '$command'..." -ForegroundColor Cyan
                        $result = Update-PowerStubGitRepo -Path $stubPath
                        if ($result.Success) {
                            Write-Host "  $($result.Message)" -ForegroundColor Green
                        }
                        else {
                            Write-Host "  $($result.Message)" -ForegroundColor Red
                        }
                    }
                    else {
                        # Update all unique git repos across all stubs
                        foreach ($stubName in $stubs.Keys) {
                            $stubConfig = $stubs[$stubName]
                            $stubPath = Get-PowerStubPath -StubConfig $stubConfig
                            $gitInfo = Get-PowerStubGitInfo -Path $stubPath
                            if ($gitInfo.IsRepo -and $gitInfo.RepoRoot -and -not $updatedRepos.ContainsKey($gitInfo.RepoRoot)) {
                                Write-Host "Updating stub '$stubName' ($($gitInfo.RepoRoot))..." -ForegroundColor Cyan
                                $result = Update-PowerStubGitRepo -Path $stubPath
                                if ($result.Success) {
                                    Write-Host "  $($result.Message)" -ForegroundColor Green
                                }
                                else {
                                    Write-Host "  $($result.Message)" -ForegroundColor Red
                                }
                                $updatedRepos[$gitInfo.RepoRoot] = $true
                            }
                        }
                        if ($updatedRepos.Count -eq 0) {
                            Write-Host "No stubs with Git repositories found." -ForegroundColor Yellow
                        }
                        else {
                            Write-Host "`nUpdated $($updatedRepos.Count) repository(ies)." -ForegroundColor Cyan
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