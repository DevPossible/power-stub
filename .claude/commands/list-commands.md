# List Commands in a Stub

Show all available commands in a registered stub.

## Arguments

- `$ARGUMENTS` - The stub name to query (optional - lists all stubs if not provided)

## Instructions

1. If no stub name provided, list all registered stubs first
2. If stub name provided:
   - Look up the stub path from configuration
   - Find all .ps1 and .exe files in the stub directory (recursively)
   - Show which folder each command is in (Commands, .beta, .draft)
   - Indicate current beta/draft visibility settings
3. Format output as a clear table showing:
   - Command name
   - Type (.ps1 or .exe)
   - Location (main/beta/draft)
   - Full path

## Commands

```powershell
Import-Module ./PowerStub/PowerStub.psm1 -Force

# Get configuration
$config = Get-PowerStubConfiguration

# List stubs
Get-PowerStubs

# If stub specified, find its commands
# Find-PowerStubCommands -Stub "<stub-name>"
```

Run these commands based on the user's arguments.
