function Invoke-CheckedCommandWithParams {
    param (
        [string] $command,
        [object[]] $psParams,
        [string] $cmdArguments
    )

    try {
        $Error.clear()
        $global:LASTEXITCODE = 0
        $exitCode = 0

        #$hasObjects = ($psParams | Where-Object {!($_ -is [String])})
        $hasObjects = $false
        if (!$cmdArguments) {
            $stringTypes = "System.String", "String"
            foreach ($param in $psParams) {
                $type = $param.GetType().FullName
                if (!($stringTypes -contains $type)) {
                    $hasObjects = $true
                    break
                }
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
            if ($cmdArguments) {
                #just use the command line as provided
                $exp = "$command --% $cmdArguments"
            }
            else {
                #use the parameters as provided by converting the array to a string
                $exp = "$command "
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
            throw $("$command exited with error code " + $exitCode)
        }
    }
    catch {
        throw $("$command exited with error code " + $exitCode)
    }
}