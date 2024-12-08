$Script:ModulePath = $PSScriptRoot

Write-Verbose "Initializing PowerStub"

#enable verbose messaging in the psm1 file
if ($MyInvocation.line -match '-verbose') {
    $VerbosePreference = 'continue'
}

#Get all files with functions in them
Write-Verbose 'Finding functions'

$privateFn = Get-ChildItem -Path $PSScriptRoot\private\functions\*.ps1;
$publicFn = Get-ChildItem -Path $PSScriptRoot\public\functions\*.ps1;

#If we are in PowerShell core, load any core specific functions
if ($IsCoreCLR) {
    Write-Verbose 'PowerShell 7 specific commands enabled'
    $publicFn += Get-ChildItem -Path $PSScriptRoot\public\functions-pscore\*.ps1;
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

#setup the Invoke-PowerStubCommand argument completer for the stub parameter
Write-Verbose "Setting up argument completer for Invoke-PowerStubCommand stub parameter"
$CommandStubCompleter = {
    param($commandName, $parameterName, $stringMatch, $commandAst, $fakeBoundParameter)
    return "test", "test2", "other"
    $stubObj = Get-PowerStubConfigurationKey 'Stubs'
    $stubs = $stubObj.Keys
    if (!$stringMatch) { 
        return $stubs | ForEach-Object {
            New-Object -Type System.Management.Automation.CompletionResult -ArgumentList @(
                $_          # completionText
                $_          # listItemText
                'ParameterValue' # resultType
                $_          # toolTip
            )
        }
    }
    
    $PartialMatches = $stubs | Where-Object { $_ -Match $stringMatch } 
    return $PartialMatches | ForEach-Object {
        New-Object -Type System.Management.Automation.CompletionResult -ArgumentList @(
            $_          # completionText
            $_          # listItemText
            'ParameterValue' # resultType
            $_          # toolTip
        )
    }
}

Register-ArgumentCompleter -CommandName Invoke-PowerStubCommand -ParameterName Stub -ScriptBlock $CommandStubCompleter

Write-Verbose "PowerStub module loaded."