function Invoke-CheckedCommandWithParams {
    param (
        [string] $command,
        [object[]] $psParams,
        [string] $cmdArguments
    )

    $Error.clear()
    $global:LASTEXITCODE = 0
    $exitCode = 0

    #$hasObjects = ($psParams | Where-Object {!($_ -is [String])})
    $hasObjects = $false
    $stringTypes = "System.String", "String"
    foreach ($param in $psParams) {
        $type = $param.GetType().FullName
        if (!($stringTypes -contains $type)) {
            $hasObjects = $true
            break
        }
    }

    if ($hasObjects) {
        $processedParams = Get-NamedParameters $psParams
        $named = $processedParams.Named
        $unnamed = $processedParams.Unnamed
        #run the command
        & "$command" @unnamed @named
    }
    else {
        #all the parameters are strings, so lets avoid splatting problems by using a more compatible method
        $exeParsing = ""
        if ($command -like '*.exe') { $exeParsing = "--% " } #trailing space is important

        if ($cmdArguments) {
            #just use the command line as provided
            $exp = "& $command $($exeParsing)$cmdArguments" #do not add a space between the exeParsing variable and the arguments variable
        }
        else {
            #use the parameters as provided by converting the array to a string
            $exp = "& $command --% "
            $exp += $psParams -join " "
        }

        Write-Debug -Message "Expression String: $exp"
        Invoke-Expression -Command $exp
    }

    $success = $?
    if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) { $exitCode = $GLOBAL:LASTEXITCODE; }
    else {
        if (Test-Path VARIABLE:LASTEXITCODE) { $exitCode = $LASTEXITCODE; }
        else { $exitCode = 0; }
    }

    if (!$success -or ($exitCode -ne 0)) {
        Write-Debug $("$command exited with error code " + $exitCode)
        Write-Debug $("params: " + $($psParams -join " "))
        # Extract just the command name for cleaner error message
        $cmdName = Split-Path -Leaf $command
        # Use Write-Host for clean output without stack trace
        Write-Host "$cmdName exited with error code $exitCode" -ForegroundColor Red
        # Set LASTEXITCODE so callers can check it
        $global:LASTEXITCODE = $exitCode
    }
}