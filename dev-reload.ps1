<#
.SYNOPSIS
    Reloads the PowerStub module for local development and testing.

.DESCRIPTION
    This script removes any existing PowerStub module from the session and
    reimports it from the local source. Use this after making changes to
    test them immediately without restarting PowerShell.

.PARAMETER Reset
    Also resets the configuration to defaults after reloading.

.EXAMPLE
    .\dev-reload.ps1
    # Reloads the module with existing configuration

.EXAMPLE
    .\dev-reload.ps1 -Reset
    # Reloads the module and resets configuration to defaults
#>
param(
    [switch]$Reset
)

$ErrorActionPreference = 'Stop'

Write-Host "Reloading PowerStub module..." -ForegroundColor Cyan

# Remove existing module if loaded
$existingModule = Get-Module -Name 'PowerStub'
if ($existingModule) {
    Write-Host "  Removing existing module..." -ForegroundColor Gray
    Remove-Module -ModuleInfo $existingModule -Force
}

# Import from local source
$modulePath = Join-Path $PSScriptRoot 'PowerStub\PowerStub.psm1'
Write-Host "  Importing from: $modulePath" -ForegroundColor Gray
Import-Module $modulePath -Force -Verbose:$false

# Optionally reset configuration
if ($Reset) {
    Write-Host "  Resetting configuration to defaults..." -ForegroundColor Gray
    Import-PowerStubConfiguration -Reset
}

# Show loaded module info
$module = Get-Module -Name 'PowerStub'
Write-Host "`nModule loaded successfully!" -ForegroundColor Green
Write-Host "  Version: $($module.Version)"
Write-Host "  Exported commands: $($module.ExportedCommands.Count)"
Write-Host "  Alias 'pstb' available: $(if (Get-Alias pstb -ErrorAction SilentlyContinue) { 'Yes' } else { 'No' })"

# Show current configuration summary
$config = Get-PowerStubConfiguration
$stubCount = $config['Stubs'].Keys.Count
Write-Host "`nConfiguration:"
Write-Host "  Registered stubs: $stubCount"
Write-Host "  Alpha commands: $(if ($config['EnablePrefix:Alpha']) { 'Enabled' } else { 'Disabled' })"
Write-Host "  Beta commands: $(if ($config['EnablePrefix:Beta']) { 'Enabled' } else { 'Disabled' })"
