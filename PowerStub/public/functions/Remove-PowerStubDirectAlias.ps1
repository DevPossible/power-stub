<#
.SYNOPSIS
    Removes a direct alias for a PowerStub stub.

.DESCRIPTION
    Removes a PowerShell function that was created as a shortcut for a specific stub.
    Also removes the alias from the saved configuration so it won't be recreated
    when the module loads.

.PARAMETER AliasName
    The name of the alias to remove.

.EXAMPLE
    Remove-PowerStubDirectAlias -AliasName dv

    Removes the 'dv' alias that was created for a stub.

.OUTPUTS
    None
#>

function Remove-PowerStubDirectAlias {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$AliasName
    )

    # Check if the alias exists in our config
    $directAliases = Get-PowerStubConfigurationKey 'DirectAliases'
    if (-not $directAliases -or -not $directAliases.ContainsKey($AliasName)) {
        throw "Direct alias '$AliasName' not found in PowerStub configuration."
    }

    # Remove the global function if it exists
    $existingCmd = Get-Command $AliasName -ErrorAction SilentlyContinue
    if ($existingCmd -and $existingCmd.CommandType -eq 'Function') {
        Remove-Item "function:$AliasName" -ErrorAction SilentlyContinue
        Write-Verbose "Removed function '$AliasName'"
    }

    # Remove from config
    $directAliases.Remove($AliasName)
    Set-PowerStubConfigurationKey 'DirectAliases' $directAliases

    Write-Verbose "Removed direct alias '$AliasName' from configuration"
}
