# arg-echo.ps1 - Test fixture for argument passing tests
# Echoes all received arguments with type information for test validation
#
# NOTE: This script uses the automatic $args variable instead of declared parameters
# to avoid conflicts with PowerStub's dynamic parameter extraction
#
# Output format:
#   ARG_COUNT:<count>
#   ARG[<index>]:<type>:<value>
#
# Example output:
#   ARG_COUNT:2
#   ARG[0]:String:hello
#   ARG[1]:Int32:42

# Use automatic $args variable to capture all arguments
$allArgs = $args

# Output argument count
Write-Output "ARG_COUNT:$($allArgs.Count)"

# Output each argument with its type
for ($i = 0; $i -lt $allArgs.Count; $i++) {
    $arg = $allArgs[$i]
    if ($null -eq $arg) {
        $type = 'null'
        $value = ''
    }
    else {
        $type = $arg.GetType().Name
        $value = $arg
    }
    Write-Output "ARG[$i]:$($type):$value"
}
