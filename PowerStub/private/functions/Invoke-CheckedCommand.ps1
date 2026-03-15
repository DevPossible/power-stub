function Invoke-CheckedCommandWithParams {
    param (
        [string] $command,
        [hashtable] $namedParams = @{},
        [object[]] $positionalArgs = @()
    )

    $global:LASTEXITCODE = 0
    $exitCode = 0

    # Use call operator with splatting instead of Invoke-Expression
    # This avoids command injection via PowerShell metacharacters in arguments
    if ($namedParams -and $namedParams.Count -gt 0) {
        if ($positionalArgs -and $positionalArgs.Count -gt 0) {
            & $command @namedParams @positionalArgs
        }
        else {
            & $command @namedParams
        }
    }
    elseif ($positionalArgs -and $positionalArgs.Count -gt 0) {
        & $command @positionalArgs
    }
    else {
        & $command
    }

    $success = $?
    if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) { $exitCode = $GLOBAL:LASTEXITCODE; }
    else {
        if (Test-Path VARIABLE:LASTEXITCODE) { $exitCode = $LASTEXITCODE; }
        else { $exitCode = 0; }
    }

    if (!$success -or ($exitCode -ne 0)) {
        Write-Debug $("$command exited with error code " + $exitCode)
        Write-Debug $("params: " + $($positionalArgs -join " "))
        # Extract just the command name for cleaner error message
        $cmdName = Split-Path -Leaf $command
        # Use Write-Host for clean output without stack trace
        Write-Host "$cmdName exited with error code $exitCode" -ForegroundColor Red
        # Set LASTEXITCODE so callers can check it
        $global:LASTEXITCODE = $exitCode
    }
}
