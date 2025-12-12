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

Register-ArgumentCompleter -CommandName Invoke-PowerStubCommand -ParameterName Stub -ScriptBlock $StubCompleter

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

Register-ArgumentCompleter -CommandName Invoke-PowerStubCommand -ParameterName Command -ScriptBlock $CommandCompleter

Write-Verbose "PowerStub module loaded."