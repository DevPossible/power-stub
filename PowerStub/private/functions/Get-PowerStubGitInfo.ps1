<#
.SYNOPSIS
  Gets Git repository information for a given path.

.DESCRIPTION
  Checks if a path is part of a Git repository and returns repository details
  including the remote URL and status information.

.PARAMETER Path
  The path to check for Git repository information.

.OUTPUTS
  PSCustomObject with properties:
  - IsRepo: Boolean indicating if path is in a git repo
  - RepoRoot: The root path of the repository
  - RemoteUrl: The URL of the origin remote (if any)
  - CurrentBranch: The current branch name
  - BehindCount: Number of commits behind the remote
  - AheadCount: Number of commits ahead of the remote

.EXAMPLE
  Get-PowerStubGitInfo -Path "C:\MyRepo"
#>

function Get-PowerStubGitInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Check if git is available
    if (-not $Script:GitAvailable) {
        return [PSCustomObject]@{
            IsRepo       = $false
            RepoRoot     = $null
            RemoteUrl    = $null
            CurrentBranch = $null
            BehindCount  = 0
            AheadCount   = 0
        }
    }

    # Ensure path exists
    if (-not (Test-Path $Path)) {
        return [PSCustomObject]@{
            IsRepo       = $false
            RepoRoot     = $null
            RemoteUrl    = $null
            CurrentBranch = $null
            BehindCount  = 0
            AheadCount   = 0
        }
    }

    $originalLocation = Get-Location
    try {
        Set-Location $Path

        # Check if this is a git repository
        $repoRoot = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
            return [PSCustomObject]@{
                IsRepo       = $false
                RepoRoot     = $null
                RemoteUrl    = $null
                CurrentBranch = $null
                BehindCount  = 0
                AheadCount   = 0
            }
        }

        # Get remote URL (origin)
        $remoteUrl = git config --get remote.origin.url 2>$null

        # Get current branch
        $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null

        # Fetch to update remote tracking info (silently)
        # Only fetch if we have a remote
        if ($remoteUrl) {
            git fetch origin --quiet 2>$null
        }

        # Get ahead/behind counts
        $behindCount = 0
        $aheadCount = 0
        if ($remoteUrl -and $currentBranch) {
            $trackingBranch = git rev-parse --abbrev-ref "@{upstream}" 2>$null
            if ($LASTEXITCODE -eq 0 -and $trackingBranch) {
                $countOutput = git rev-list --left-right --count "$trackingBranch...HEAD" 2>$null
                if ($LASTEXITCODE -eq 0 -and $countOutput) {
                    $counts = $countOutput -split '\s+'
                    if ($counts.Count -ge 2) {
                        $behindCount = [int]$counts[0]
                        $aheadCount = [int]$counts[1]
                    }
                }
            }
        }

        return [PSCustomObject]@{
            IsRepo        = $true
            RepoRoot      = $repoRoot
            RemoteUrl     = $remoteUrl
            CurrentBranch = $currentBranch
            BehindCount   = $behindCount
            AheadCount    = $aheadCount
        }
    }
    finally {
        Set-Location $originalLocation
    }
}
