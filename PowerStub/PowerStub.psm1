$Script:PSTBSettings = @{
    'ModulePath'         = $PSScriptRoot
    'ConfigFile'         = Join-Path $PSScriptRoot 'PowerStub.json'
    'InternalConfigKeys' = @('InternalConfigKeys', 'ModulePath', 'ConfigFile')
    'InvokeAlias'        = 'pstb'
    'Collections'        = @{}
}

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
Import-PowerStubConfiguration

#export public functions only

# helper functions
[string[]]$exports = @($publicFn | Select-Object -ExpandProperty BaseName)
Write-Verbose "Exporting $($exports.Count) functions"
Export-ModuleMember -Function $exports

# stub functions
#Export-ModuleMember -Function 'Invoke-PowerStubCommand'
New-Alias $Script:PSTBSettings['InvokeAlias'] Invoke-PowerStubCommand
Export-ModuleMember -Alias $Script:PSTBSettings['InvokeAlias']

# management functions
#Export-ModuleMember -Function 'New-PowerStubCollection'
#Export-ModuleMember -Function 'New-PowerStubCommand'
Write-Verbose "PowerStub module loaded."