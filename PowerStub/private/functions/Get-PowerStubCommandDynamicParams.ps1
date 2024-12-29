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
    $RuntimeParamDic = New-Object  System.Management.Automation.RuntimeDefinedParameterDictionary

    if (!$stub -or !$command) {
        Write-Warning "Stub and Command are required."
        return $RuntimeParamDic
    }
    Write-Debug "Stub: $stub"
    Write-Debug "Command: $command"

    #load parameters from the command
    $commandObj = Get-PowerStubCommand $stub $command
    Write-Debug "Dyn Param Command: $($commandObj.Name)"
    if (!$commandObj) {
        Write-Warning "Command '$command' not found in the configuration."
        return $RuntimeParamDic
    }

    Write-Debug "param count: $($commandObj.Parameters.Count)"

    foreach ($paramKey in $commandObj.Parameters.Keys) {
        $param = $commandObj.Parameters[$paramKey]
        $isMandatory = $param.Attributes | Where-Object { $_.TypeNameOfValue -eq 'System.Management.Automation.ParameterAttribute' } | ForEach-Object { $_.Mandatory }
        $name = $param.Name
        $type = $param.ParameterType
        Write-Debug "Adding dynamic parameter '$name' with type '$type' and mandatory '$isMandatory'"
        New-DynamicParam -Name $name -Type $type -Mandatory:$isMandatory -DPDictionary $RuntimeParamDic
    }

    return $RuntimeParamDic

}