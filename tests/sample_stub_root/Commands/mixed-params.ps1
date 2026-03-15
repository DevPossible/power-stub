# mixed-params.ps1 - Test fixture for mixed named + positional argument passing
# Has declared parameters AND captures remaining args via ValueFromRemainingArguments
# Uses PositionalBinding=$false so extra args don't try to bind to declared params
#
# Output format (JSON):
#   { "Named": { "Env": "value", "Count": N }, "Extra": ["arg1", "arg2"], "Switch": true/false }
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter()]
    [string]$Env = "default",

    [Parameter()]
    [int]$Count = 0,

    [Parameter()]
    [switch]$Force,

    [Parameter(ValueFromRemainingArguments)]
    [object[]]$ExtraArgs
)

$result = @{
    Named = @{
        Env   = $Env
        Count = $Count
    }
    Switch = $Force.IsPresent
    Extra  = @(if ($ExtraArgs) { $ExtraArgs } else { @() })
    BoundKeys = @($PSBoundParameters.Keys)
}

$result | ConvertTo-Json -Depth 3 -Compress
