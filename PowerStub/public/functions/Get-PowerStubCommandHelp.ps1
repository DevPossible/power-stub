<#
.SYNOPSIS
    Displays help for a PowerStub command.

.DESCRIPTION
    Retrieves and displays the PowerShell comment-based help for a command
    in a registered stub. This includes synopsis, description, parameters,
    and examples.

.PARAMETER Stub
    The name of the stub containing the command.

.PARAMETER Command
    The name of the command to get help for.

.EXAMPLE
    Get-PowerStubCommandHelp -Stub DevOps -Command deploy

    Displays full help for the deploy command in the DevOps stub.

.EXAMPLE
    pstb help DevOps deploy

    Same as above, using the virtual verb syntax.

.OUTPUTS
    PowerShell help object
#>

function Get-PowerStubCommandHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Stub,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Command
    )

    # Verify stub exists
    $stubs = Get-PowerStubConfigurationKey 'Stubs'
    if (-not ($stubs.Keys -contains $Stub)) {
        throw "Stub '$Stub' not found. Use Get-PowerStubs to see registered stubs."
    }

    # Get the command
    $cmd = Get-PowerStubCommand -Stub $Stub -Command $Command
    if (-not $cmd) {
        throw "Command '$Command' not found in stub '$Stub'."
    }

    # Get and return help
    $help = Get-Help $cmd.Path -Full -ErrorAction SilentlyContinue

    if (-not $help -or $help.Synopsis -eq $cmd.Path) {
        # No help defined, return basic info
        Write-Warning "No help documentation found for '$Command'. Showing basic info."
        [PSCustomObject]@{
            Name        = $Command
            Stub        = $Stub
            Path        = $cmd.Path
            Synopsis    = "No help available"
            Description = "This command does not have comment-based help defined."
        }
    }
    else {
        $help
    }
}
