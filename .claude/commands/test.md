# Run PowerStub Tests

Run Pester tests for the PowerStub module.

## Instructions

1. Import the Pester module if not already loaded
2. Run tests from `tests/` directory (at repo root)
3. Show test results summary
4. If any tests fail, analyze the failures and suggest fixes

## Command

```powershell
Import-Module Pester -ErrorAction SilentlyContinue
Invoke-Pester -Path "./tests/" -Output Detailed
```

Run this command and report the results to the user.
