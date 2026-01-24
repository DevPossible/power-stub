<#
.SYNOPSIS
    Builds and installs the PowerStub module locally.

.DESCRIPTION
    This script updates the locally installed PowerStub module with the current
    development version. It:
    1. Runs tests to verify the module works
    2. Finds or creates the local module installation path
    3. Copies the module files to the installation path
    4. Reloads the module in the current session

.PARAMETER SkipTests
    Skip running tests before installation (not recommended).

.PARAMETER Force
    Overwrite existing installation without confirmation.

.PARAMETER Scope
    Installation scope: CurrentUser (default) or AllUsers (requires admin).

.EXAMPLE
    .\local-release.ps1
    # Runs tests and installs to CurrentUser scope

.EXAMPLE
    .\local-release.ps1 -SkipTests -Force
    # Quick install without tests or confirmation

.EXAMPLE
    .\local-release.ps1 -Scope AllUsers
    # Install for all users (requires admin)
#>
[CmdletBinding()]
param(
    [switch]$SkipTests,
    [switch]$Force,
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser'
)

$ErrorActionPreference = 'Stop'

# Colors for output
function Write-Step { param([string]$Message) Write-Host "`n>> $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "   $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "   $Message" -ForegroundColor Gray }
function Write-Warn { param([string]$Message) Write-Host "   $Message" -ForegroundColor Yellow }

$moduleName = 'PowerStub'
$sourceDir = Join-Path $PSScriptRoot $moduleName

# Verify source exists
Write-Step "Checking source module..."
if (-not (Test-Path $sourceDir)) {
    throw "Source module not found at: $sourceDir"
}
Write-Success "Source found: $sourceDir"

# Read version from manifest
$manifestPath = Join-Path $sourceDir "$moduleName.psd1"
if (Test-Path $manifestPath) {
    $manifest = Import-PowerShellDataFile $manifestPath
    $version = $manifest.ModuleVersion
    Write-Info "Module version: $version"
}
else {
    Write-Warn "Manifest not found, version unknown"
    $version = "unknown"
}

# Run tests
if (-not $SkipTests) {
    Write-Step "Running tests..."
    $testScript = Join-Path $PSScriptRoot "dev-test.ps1"
    if (Test-Path $testScript) {
        & $testScript -Output Normal
        if ($LASTEXITCODE -ne 0) {
            throw "Tests failed. Fix issues before installing."
        }
        Write-Success "All tests passed"
    }
    else {
        Write-Warn "Test script not found, skipping tests"
    }
}
else {
    Write-Warn "Skipping tests (not recommended)"
}

# Determine installation path
Write-Step "Determining installation path..."
if ($Scope -eq 'AllUsers') {
    $modulesPath = $env:ProgramFiles | Join-Path -ChildPath 'PowerShell\Modules'

    # Check for admin
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw "AllUsers scope requires administrator privileges. Run as admin or use -Scope CurrentUser"
    }
}
else {
    # CurrentUser scope - use Documents\PowerShell\Modules
    $modulesPath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
}

$installPath = Join-Path $modulesPath $moduleName
Write-Info "Installation path: $installPath"

# Check for existing installation
if (Test-Path $installPath) {
    Write-Warn "Existing installation found"

    if (-not $Force) {
        $confirm = Read-Host "Overwrite existing installation? (y/N)"
        if ($confirm -notmatch '^[Yy]') {
            Write-Host "Aborted." -ForegroundColor Yellow
            exit 0
        }
    }

    # Remove existing module from session
    Write-Step "Removing existing module from session..."
    $loadedModule = Get-Module -Name $moduleName
    if ($loadedModule) {
        Remove-Module -Name $moduleName -Force
        Write-Success "Module unloaded from session"
    }

    # Remove existing files
    Write-Step "Removing existing installation..."
    Remove-Item -Path $installPath -Recurse -Force
    Write-Success "Existing installation removed"
}

# Create installation directory
Write-Step "Installing module..."
New-Item -Path $installPath -ItemType Directory -Force | Out-Null
Write-Success "Created: $installPath"

# Copy files
Write-Info "Copying module files..."
$items = Get-ChildItem -Path $sourceDir -Recurse
$fileCount = 0
foreach ($item in $items) {
    $relativePath = $item.FullName.Substring($sourceDir.Length + 1)
    $targetPath = Join-Path $installPath $relativePath

    if ($item.PSIsContainer) {
        New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
    }
    else {
        Copy-Item -Path $item.FullName -Destination $targetPath -Force
        $fileCount++
    }
}
Write-Success "Copied $fileCount files"

# Import the new module
Write-Step "Loading installed module..."
Import-Module $installPath -Force -Global
$loadedModule = Get-Module -Name $moduleName
if ($loadedModule) {
    Write-Success "Module loaded: $($loadedModule.Name) v$($loadedModule.Version)"
}
else {
    Write-Warn "Module installed but not loaded"
}

# Verify installation
Write-Step "Verifying installation..."
$installedModule = Get-Module -ListAvailable -Name $moduleName |
    Where-Object { $_.ModuleBase -eq $installPath } |
    Select-Object -First 1

if ($installedModule) {
    Write-Success "Verified: $($installedModule.Name) v$($installedModule.Version)"
    Write-Info "Path: $($installedModule.ModuleBase)"
}
else {
    Write-Warn "Could not verify installation"
}

# Summary
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Green
Write-Host " Local installation complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Module: $moduleName v$version" -ForegroundColor Cyan
Write-Host "Scope:  $Scope" -ForegroundColor Cyan
Write-Host "Path:   $installPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "The module is now available in new PowerShell sessions." -ForegroundColor Gray
Write-Host "Use 'Import-Module $moduleName -Force' to reload in current session." -ForegroundColor Gray
Write-Host ""
