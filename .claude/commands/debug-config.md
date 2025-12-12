# Debug PowerStub Configuration

Diagnose configuration issues with PowerStub.

## Instructions

1. Read the PowerStub.json file and display its contents
2. Check if all stub paths exist and are accessible
3. Verify the module can be imported successfully
4. List all registered stubs and their status
5. Check for common issues:
   - Missing or malformed JSON
   - Paths that don't exist
   - Permission issues
   - Missing required keys

## Commands to Run

```powershell
# Check if config file exists
Test-Path "./PowerStub/PowerStub.json"

# Read and display config
Get-Content "./PowerStub/PowerStub.json" | ConvertFrom-Json | Format-List

# Import module and check config
Import-Module ./PowerStub/PowerStub.psm1 -Force
Get-PowerStubConfiguration

# List stubs and verify paths
$stubs = Get-PowerStubs
foreach ($stub in $stubs.GetEnumerator()) {
    $exists = Test-Path $stub.Value
    Write-Host "$($stub.Key): $($stub.Value) - $(if($exists){'OK'}else{'MISSING'})"
}
```

Run these diagnostic commands and report findings to the user.
