# Create a New PowerStub Command

Create a new PowerShell command script for a stub.

## Arguments

- `$ARGUMENTS` - Should contain: `<stub-name> <command-name> [description]`

## Instructions

1. Parse the arguments to extract stub name, command name, and optional description
2. Look up the stub path from PowerStub.json configuration
3. Create a new .ps1 file in the stub's Commands folder
4. Use proper PowerShell script structure with:
   - Comment-based help (Synopsis, Description, Parameter, Example)
   - `[CmdletBinding()]` attribute
   - `param()` block
   - Clear, documented code structure
5. If no description provided, ask the user what the command should do
6. After creating the file, show the user the path and offer to open it

Example usage: `/new-command DevOps deploy-app "Deploys application to specified environment"`
