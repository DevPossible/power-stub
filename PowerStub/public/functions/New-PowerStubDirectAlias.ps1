<#
.SYNOPSIS
    Creates a direct alias for a PowerStub stub.

.DESCRIPTION
    Creates a PowerShell function that acts as a shortcut for a specific stub.
    Instead of typing 'pstb DevOps <command>', you can use a shorter alias like 'dv <command>'.

    The alias supports full tab completion for both command names and command parameters.

.PARAMETER AliasName
    The name of the alias to create (e.g., 'dv' for DevOps).

.PARAMETER Stub
    The name of the stub to create an alias for.

.PARAMETER Force
    Overwrites the alias if it already exists.

.EXAMPLE
    New-PowerStubDirectAlias -AliasName dv -Stub DevOps

    Creates an alias 'dv' for the DevOps stub. Now you can run:
        dv deploy -Environment prod
    Instead of:
        pstb DevOps deploy -Environment prod

.EXAMPLE
    New-PowerStubDirectAlias -AliasName dv -Stub DevOps -Force

    Overwrites an existing 'dv' alias.

.OUTPUTS
    PSCustomObject with alias information and usage instructions.
#>

function New-PowerStubDirectAlias {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[a-zA-Z][a-zA-Z0-9_-]*$')]
        [string]$AliasName,

        [Parameter(Mandatory = $true)]
        [string]$Stub,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Verify stub exists
    $stubs = Get-PowerStubConfigurationKey 'Stubs'
    if (-not ($stubs.Keys -contains $Stub)) {
        throw "Stub '$Stub' not found. Register it first with New-PowerStub."
    }

    # Check if function already exists
    $existingCmd = Get-Command $AliasName -ErrorAction SilentlyContinue
    if ($existingCmd -and -not $Force) {
        throw "A command named '$AliasName' already exists. Use -Force to overwrite."
    }

    # Create the function in global scope
    $functionBody = @"
function global:$AliasName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$false, Position = 0)]
        [string]`$Command,

        [Parameter(DontShow = `$true, ValueFromRemainingArguments = `$true)]
        [object[]]`$RemainingArgs
    )

    DynamicParam {
        `$stubName = '$Stub'
        `$commandValue = `$PSBoundParameters['Command']

        if (`$commandValue -and (Get-Module PowerStub)) {
            `$module = Get-Module PowerStub
            `$RuntimeParamDic = & `$module { param(`$s, `$c) Get-PowerStubCommandDynamicParams `$s `$c } `$stubName `$commandValue
            return `$RuntimeParamDic
        }

        return New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    }

    end {
        `$stubName = '$Stub'

        if (-not `$Command) {
            # List commands
            `$module = Get-Module PowerStub
            & `$module { param(`$s) Find-PowerStubCommands `$s } `$stubName
            return
        }

        # Get the command object
        `$commandObj = Get-PowerStubCommand `$stubName `$Command
        if (-not `$commandObj) {
            throw "Command '`$stubName : `$Command' not found!"
        }

        # Parse arguments from invocation line
        `$line = `$MyInvocation.Line
        Write-Debug "line: `$line"

        # Find where the command name ends and arguments begin
        `$cmdArgs = `$null
        `$i = `$line.IndexOf(`$Command)
        if (`$i -ge 0) {
            `$cmdArgs = `$line.Substring(`$i + `$Command.Length).Trim()
        }

        `$cmd = `$commandObj.Path
        `$module = Get-Module PowerStub

        # Execute the command
        if (`$cmdArgs) {
            Write-Host "Invoking `$cmd with arguments: `$cmdArgs"
            & `$module { param(`$c, `$p, `$a, `$t) Invoke-CheckedCommandWithParams `$c `$p `$a `$t } `$cmd `$null `$cmdArgs `$true
        }
        elseif (`$RemainingArgs -and `$RemainingArgs.Count -gt 0) {
            Write-Host "Invoking `$cmd with positional arguments"
            & `$module { param(`$c, `$p, `$a, `$t) Invoke-CheckedCommandWithParams `$c `$p `$a `$t } `$cmd `$RemainingArgs `$null `$true
        }
        else {
            Write-Host "Invoking `$cmd"
            & `$module { param(`$c, `$p, `$a, `$t) Invoke-CheckedCommandWithParams `$c `$p `$a `$t } `$cmd `$null `$null `$true
        }
    }
}
"@

    # Create the function
    Invoke-Expression $functionBody

    # Register ArgumentCompleter for -Command parameter
    $commandCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

        $commands = @(Find-PowerStubCommands $Stub)
        if (-not $commands) { return @() }

        $commandNames = @($commands | ForEach-Object {
            $name = $_.BaseName
            if ($name -match '^(alpha|beta)\.(.+)$') {
                $Matches[2]
            } else {
                $name
            }
        } | Select-Object -Unique)

        if (-not $wordToComplete) { return $commandNames }

        $commandNames | Where-Object { $_ -like "$wordToComplete*" }
    }.GetNewClosure()

    Register-ArgumentCompleter -CommandName $AliasName -ParameterName Command -ScriptBlock $commandCompleter

    # Store in config for re-registration on module load
    $directAliases = Get-PowerStubConfigurationKey 'DirectAliases'
    if (-not $directAliases) {
        $directAliases = @{}
    }
    $directAliases[$AliasName] = $Stub
    Set-PowerStubConfigurationKey 'DirectAliases' $directAliases

    # Return info object
    [PSCustomObject]@{
        AliasName = $AliasName
        Stub      = $Stub
        StubPath  = $stubs[$Stub]
        Usage     = @"
Alias '$AliasName' created for stub '$Stub'.

Usage:
    $AliasName                         # List available commands
    $AliasName <command>               # Run a command
    $AliasName <command> <Tab>         # Tab complete command names
    $AliasName <command> -<Tab>        # Tab complete command parameters

To make persistent, add to your `$PROFILE:
    Import-Module PowerStub

The alias is automatically recreated when the PowerStub module loads.
"@
    }
}
