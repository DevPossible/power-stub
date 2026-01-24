# no-args.ps1 - Test fixture for zero-argument invocation
# This command expects NO arguments. If any are received, it reports them.
# Used to detect issues like the --% token being incorrectly passed.
#
# Output format:
#   NO_ARGS_SUCCESS (if no arguments received)
#   or
#   UNEXPECTED_ARG_COUNT:<count>
#   UNEXPECTED_ARG[<index>]:<value>

$allArgs = $args

if ($allArgs.Count -eq 0) {
    Write-Output "NO_ARGS_SUCCESS"
}
else {
    Write-Output "UNEXPECTED_ARG_COUNT:$($allArgs.Count)"
    for ($i = 0; $i -lt $allArgs.Count; $i++) {
        $arg = $allArgs[$i]
        Write-Output "UNEXPECTED_ARG[$i]:$arg"
    }
    # Exit with error to make test failures obvious
    exit 1
}
