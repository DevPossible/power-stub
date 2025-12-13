# arg-dump.ps1 - Test fixture for detailed parameter dump
# Captures both named parameters and remaining args
# Outputs structured data for test parsing
#
# NOTE: Uses simple param block without CmdletBinding to avoid
# common parameter conflicts with PowerStub's dynamic parameter extraction
#
# Output format: JSON-like structure with parameter details

param(
    [string]$StringParam,
    [int]$IntParam,
    [switch]$SwitchParam,
    [string[]]$ArrayParam,
    [hashtable]$HashParam
)

# Build result object
$result = @{
    BoundParameters = @{}
    ExtraArgs       = @()
    PSBoundParams   = @($PSBoundParameters.Keys)
}

# Capture bound parameters with type info
foreach ($key in $PSBoundParameters.Keys) {
    $val = $PSBoundParameters[$key]

    if ($null -eq $val) {
        $result.BoundParameters[$key] = @{
            Value = $null
            Type  = 'null'
        }
    }
    elseif ($val -is [switch]) {
        $result.BoundParameters[$key] = @{
            Value = $val.IsPresent
            Type  = 'Switch'
        }
    }
    elseif ($val -is [array]) {
        $result.BoundParameters[$key] = @{
            Value = @($val)
            Type  = 'Array'
            Count = $val.Count
        }
    }
    elseif ($val -is [hashtable]) {
        $result.BoundParameters[$key] = @{
            Value = $val
            Type  = 'Hashtable'
            Keys  = @($val.Keys)
        }
    }
    else {
        $result.BoundParameters[$key] = @{
            Value = "$val"
            Type  = $val.GetType().Name
        }
    }
}

# Capture extra args via automatic $args variable
if ($args) {
    $result.ExtraArgs = @($args | ForEach-Object {
            if ($null -eq $_) {
                @{ Value = $null; Type = 'null' }
            }
            else {
                @{ Value = "$_"; Type = $_.GetType().Name }
            }
        })
}

# Output as JSON for easy parsing
$result | ConvertTo-Json -Depth 5 -Compress

# Also output human-readable summary
Write-Output ""
Write-Output "=== SUMMARY ==="
Write-Output "Bound Parameters: $($PSBoundParameters.Keys -join ', ')"
if ($StringParam) { Write-Output "StringParam: $StringParam" }
if ($PSBoundParameters.ContainsKey('IntParam')) { Write-Output "IntParam: $IntParam" }
if ($SwitchParam) { Write-Output "SwitchParam: True" }
if ($ArrayParam) { Write-Output "ArrayParam: [$($ArrayParam -join ', ')]" }
if ($HashParam) { Write-Output "HashParam: $($HashParam | ConvertTo-Json -Compress)" }
if ($args) { Write-Output "Extra Args: $($args -join ', ')" }
