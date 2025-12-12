$Script:ModulePath = $PSScriptRoot

Write-Verbose "Initializing PowerStub"

#enable verbose messaging in the psm1 file
if ($MyInvocation.line -match '-verbose') {
    $VerbosePreference = 'continue'
}

#Get all files with functions in them
Write-Verbose 'Finding functions'

$privateFn = Get-ChildItem -Path $PSScriptRoot\Private\functions\*.ps1;
$publicFn = Get-ChildItem -Path $PSScriptRoot\Public\functions\*.ps1;

#If we are in PowerShell core, load any core specific functions
if ($IsCoreCLR) {
    Write-Verbose 'PowerShell 7 specific commands enabled'
    $publicFn += Get-ChildItem -Path $PSScriptRoot\Public\functions-pscore\*.ps1;
}

# Load all functions using 'dot' import
Write-Verbose 'Dot-sourcing functions'
($publicFn + $privateFn) | ForEach-Object -Process { Write-Verbose $_.FullName; . $_.FullName }

#load the configuration
$Script:PSTBSettings = Get-PowerStubConfigurationDefaults
Import-PowerStubConfiguration

#export public functions only
[string[]]$exports = @($publicFn | Select-Object -ExpandProperty BaseName)
Write-Verbose "Exporting $($exports.Count) functions"
Export-ModuleMember -Function $exports

# setup and export the main alias
$alias = Get-PowerStubConfigurationKey 'InvokeAlias'
Write-Verbose "Creating Invoke-PowerStubCommand alias as: $alias"
New-Alias $alias Invoke-PowerStubCommand
Export-ModuleMember -Alias $alias

#setup the Invoke-PowerStubCommand argument completer for the STUB parameter
Write-Verbose "Setting up argument completer for Invoke-PowerStubCommand STUB parameter"
$StubCompleter = {
    param($commandName, $parameterName, $stringMatch, $commandAst, $fakeBoundParameters)

    $stubs = Get-PowerStubConfigurationKey 'Stubs'
    if (!$stringMatch) { return @($stubs.Keys) }

    $PartialMatches = @($stubs.Keys | Where-Object { $_ -like "$stringMatch*" })
    return $PartialMatches
}

# Register for both the function and the alias
Register-ArgumentCompleter -CommandName Invoke-PowerStubCommand -ParameterName Stub -ScriptBlock $StubCompleter
Register-ArgumentCompleter -CommandName $alias -ParameterName Stub -ScriptBlock $StubCompleter

#setup the Invoke-PowerStubCommand argument completer for the COMMAND parameter
Write-Verbose "Setting up argument completer for Invoke-PowerStubCommand COMMAND parameter"
$CommandCompleter = {
    param($commandName, $parameterName, $stringMatch, $commandAst, $fakeBoundParameters)

    $stub = $fakeBoundParameters['Stub']
    if (!$stub) { return @() }

    $commands = @(Find-PowerStubCommands $stub)
    if (!$commands) { return @() }

    # Get base names and strip alpha./beta. prefixes for user-friendly completion
    $commandNames = @($commands | ForEach-Object {
        $name = $_.BaseName
        # Strip alpha. or beta. prefix if present
        if ($name -match '^(alpha|beta)\.(.+)$') {
            $Matches[2]
        } else {
            $name
        }
    } | Select-Object -Unique)

    if (!$stringMatch) { return $commandNames }

    $PartialMatches = $commandNames | Where-Object { $_ -like "$stringMatch*" }
    return $PartialMatches
}

# Register for both the function and the alias
Register-ArgumentCompleter -CommandName Invoke-PowerStubCommand -ParameterName Command -ScriptBlock $CommandCompleter
Register-ArgumentCompleter -CommandName $alias -ParameterName Command -ScriptBlock $CommandCompleter

# Ensure PSReadLine Tab completion is properly configured
# PSReadLine is required for interactive tab completion in modern PowerShell terminals
Write-Verbose "Checking PSReadLine Tab completion setup"
$psrlModule = Get-Module PSReadLine
if ($psrlModule) {
    # PSReadLine is loaded - check if Tab is bound to a completion function
    $tabHandler = Get-PSReadLineKeyHandler -Bound -ErrorAction SilentlyContinue | Where-Object { $_.Key -eq 'Tab' }
    if (-not $tabHandler) {
        Write-Verbose "Tab key not bound - setting up Tab completion"
        try {
            Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction Stop
            Write-Verbose "Tab key bound to MenuComplete"
        } catch {
            Write-Warning "PowerStub: Could not configure Tab completion. You may need to add 'Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete' to your profile."
        }
    } else {
        Write-Verbose "Tab key already bound to: $($tabHandler.Function)"
    }
} else {
    # PSReadLine not loaded - this is unusual in interactive sessions
    # Don't warn here as this might be a non-interactive context (tests, scripts, etc.)
    Write-Verbose "PSReadLine not loaded - Tab completion may not work interactively"
}

# NOTE: We intentionally do NOT override TabExpansion2 as it can break tab completion
# for all commands in some environments. The core completion functionality (stub names,
# command names, and dynamic parameters) works via Register-ArgumentCompleter which
# doesn't require TabExpansion2.
#
# Trade-off: When using positional syntax like "pstb DevOps deploy -<Tab>", the
# completions will still include -stub and -command even though they're already bound.
# This is a minor UX issue that's preferable to potentially breaking all tab completion.

Write-Verbose "PowerStub module loaded."