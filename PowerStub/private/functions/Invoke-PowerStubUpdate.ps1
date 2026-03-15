<#
.SYNOPSIS
    Handles the 'pstb update' virtual verb for updating git repositories.

.DESCRIPTION
    Updates git repositories for registered stubs. Supports updating all stubs
    or a specific stub, with an optional --check flag for status-only mode.

.PARAMETER Command
    The command argument (may contain a stub name).

.PARAMETER RemainingArgs
    Additional arguments (may contain --check flag or stub name).

.OUTPUTS
    None. Writes status information to the host.
#>

function Invoke-PowerStubUpdate {
    [CmdletBinding()]
    param(
        [string]$Command,
        [object[]]$RemainingArgs
    )

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
    if ($Command) { $allArgs += $Command }
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
}
