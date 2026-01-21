<#
.SYNOPSIS
  Gets the dynamic parameters for a command.

.DESCRIPTION

.LINK

.PARAMETER

.INPUTS
None. You cannot pipe objects to Invoke-Authenticate.

.OUTPUTS

.EXAMPLES

#>

function Get-PowerStubCommandDynamicParams {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false, Position = 0)]
        [string] $stub,
        [parameter(Mandatory = $false, Position = 1)]
        [string] $command
    )

    #result array
    $RuntimeParamDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

    # Silently return empty dictionary if stub or command not provided
    # (this happens during tab completion when user hasn't finished typing)
    if (!$stub -or !$command) {
        return $RuntimeParamDic
    }
    Write-Debug "Stub: $stub"
    Write-Debug "Command: $command"

    # Load parameters from the command (suppress warnings during tab completion)
    $commandObj = Get-PowerStubCommand $stub $command -WarningAction SilentlyContinue
    Write-Debug "Dyn Param Command: $($commandObj.Name)"
    if (!$commandObj) {
        # Silently return - command may not exist yet during tab completion
        return $RuntimeParamDic
    }

    Write-Debug "param count: $($commandObj.Parameters.Count)"

    # Common parameters to exclude (already provided by [CmdletBinding()])
    $commonParams = @(
        'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction',
        'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable',
        'OutBuffer', 'PipelineVariable', 'ProgressAction'
    )

    foreach ($paramKey in $commandObj.Parameters.Keys) {
        # Skip common parameters - they're already defined by [CmdletBinding()]
        if ($paramKey -in $commonParams) {
            Write-Debug "Skipping common parameter '$paramKey'"
            continue
        }
        $param = $commandObj.Parameters[$paramKey]
        $isMandatory = $param.Attributes | Where-Object { $_.TypeNameOfValue -eq 'System.Management.Automation.ParameterAttribute' } | ForEach-Object { $_.Mandatory }
        $name = $param.Name
        $type = $param.ParameterType
        Write-Debug "Adding dynamic parameter '$name' with type '$type' and mandatory '$isMandatory'"
        New-DynamicParam -Name $name -Type $type -Mandatory:$isMandatory -DPDictionary $RuntimeParamDic
    }

    return $RuntimeParamDic

}