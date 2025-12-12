# Add a New PowerStub Module Function

Scaffold a new function for the PowerStub module itself.

## Arguments

- `$ARGUMENTS` - Should contain: `<public|private> <Verb-PowerStub*Name> [description]`

## Instructions

1. Parse arguments for scope (public/private), function name, and description
2. Validate function name follows PowerShell naming conventions:
   - Must use approved verb (Get, Set, New, Remove, Enable, Disable, Invoke, Import, Export, etc.)
   - Should include "PowerStub" in the noun
3. Create the function file in the appropriate folder:
   - `PowerStub/public/functions/` for exported functions
   - `PowerStub/private/functions/` for internal helpers
4. Use this template structure:

```powershell
function Verb-PowerStubNoun {
    <#
    .SYNOPSIS
        Brief description
    .DESCRIPTION
        Detailed description
    .PARAMETER ParamName
        Parameter description
    .EXAMPLE
        Example usage
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RequiredParam
    )

    begin {
        # Initialization code
    }

    process {
        # Main logic
    }

    end {
        # Cleanup code
    }
}
```

5. If adding a public function, remind user it will be auto-exported
6. Suggest adding corresponding Pester tests

Example: `/add-function public Get-PowerStubCommandHelp "Gets help for a stub command"`
