param(
    [string]$stringParam1,
    [string]$stringParam2,
    [int]$intParam1,
    [bool]$boolParam1,
    [string[]]$arrayParam1,
    [hashtable]$hashParam1,
    [datetime]$dateParam1,
    [double]$doubleParam1,
    [float]$floatParam1,
    [decimal]$decimalParam1,
    [guid]$guidParam1,
    [char]$charParam1,
    [byte]$byteParam1,
    [long]$longParam1,
    [short]$shortParam1,
    [sbyte]$sbyteParam1,    
    [DateTimeOffset]$dateTimeOffsetParam1,
    [TimeSpan]$timeSpanParam1,
    [switch]$switchParam1,
    [switch]$switchParam2,
    [switch]$switchParam3
)

Write-Host "remove-data.ps1 called with the following parameters:"

$PSBoundParameters | Format-Table
if ($args) {
    "Args:"
    $args | Format-Table
}