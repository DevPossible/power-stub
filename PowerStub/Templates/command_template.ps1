<#
.SYNOPSIS
    Brief description of what this command does.

.DESCRIPTION
    Detailed description of the command's purpose and behavior.

.PARAMETER Environment
    The target environment (e.g., dev, staging, prod).

.EXAMPLE
    pstb MyStub my-command -Environment prod

    Runs the command targeting the production environment.
#>
param(
    [Parameter(Position = 0)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment = 'dev'
)

$ErrorActionPreference = 'Stop'

Write-Host "Running my-command for environment: $Environment" -ForegroundColor Cyan

# Your command logic here
# ...

Write-Host "Done." -ForegroundColor Green
