# exit-code.ps1 - Test fixture for exit code propagation
# Exits with the specified exit code (default: 0)
#
# Output format:
#   EXIT_CODE:<code>
param(
    [int]$Code = 0
)

Write-Output "EXIT_CODE:$Code"
exit $Code
