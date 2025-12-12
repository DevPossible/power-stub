# PowerStub

A PowerShell module for organizing scripts, executables, and CLI tools using command proxies. Stop cluttering your PATH - organize your tools into logical namespaces and access them through a single entry point.

## The Problem

As your collection of PowerShell scripts and CLI tools grows, you face a common challenge:

- Scripts scattered across multiple directories
- Adding every folder to PATH becomes unmanageable
- No logical organization for related tools
- Difficult to remember where each tool lives

## The Solution

PowerStub creates **command proxies** (called "stubs") that serve as namespaced entry points to your organized tools:

```powershell
# Instead of remembering paths or adding to PATH:
C:\Tools\DevOps\Scripts\Deployment\deploy-app.ps1 -Environment prod

# Use a simple, organized command:
pstb DevOps deploy-app -Environment prod
```

## Features

- **Namespace Organization**: Group related tools under logical stub names
- **Tab Completion**: Full IntelliSense for stub names, commands, and parameters
- **Dynamic Parameters**: Automatically inherits parameters from target commands
- **Multi-format Support**: Works with `.ps1` scripts and `.exe` executables
- **Lifecycle Folders**: Built-in support for `.draft` and `.beta` command stages
- **Zero PATH Pollution**: Single alias (`pstb`) provides access to all your tools

## Installation

```powershell
# Clone the repository
git clone https://github.com/DevPossible/PowerStub.git

# Import the module
Import-Module ./PowerStub/PowerStub/PowerStub.psm1

# Add to your PowerShell profile for persistent use
Add-Content $PROFILE "`nImport-Module 'C:\path\to\PowerStub\PowerStub\PowerStub.psm1'"
```

## Quick Start

### 1. Create a New Stub

```powershell
# Register a stub for your DevOps tools
New-PowerStub -Name "DevOps" -Path "C:\Tools\DevOps"
```

This creates the following folder structure:

```text
C:\Tools\DevOps\
├── Commands\       # Main production commands
├── .draft\         # Work-in-progress commands (hidden by default)
├── .beta\          # Beta commands (hidden by default)
└── .tests\         # Test files
```

### 2. Add Commands

Place your scripts or executables in the `Commands` folder (or any subfolder):

```powershell
# C:\Tools\DevOps\Commands\deploy-app.ps1
param(
    [Parameter(Mandatory)]
    [string]$Environment,

    [string]$Version = "latest"
)

Write-Host "Deploying to $Environment with version $Version"
```

### 3. Use Your Commands

```powershell
# Tab completion works for stub names
pstb Dev<TAB>  # Completes to "DevOps"

# Tab completion works for commands
pstb DevOps dep<TAB>  # Completes to "deploy-app"

# Tab completion works for parameters
pstb DevOps deploy-app -Env<TAB>  # Completes to "-Environment"

# Execute the command
pstb DevOps deploy-app -Environment prod -Version 2.0.1
```

## Core Commands

### Stub Management

| Command | Description |
|---------|-------------|
| `New-PowerStub -Name <name> -Path <path>` | Register a new stub and create folder structure |
| `Remove-PowerStub -Name <name>` | Unregister a stub (files remain) |
| `Get-PowerStubs` | List all registered stubs |
| `Get-PowerStubCommand -Stub <name> -Command <cmd>` | Get command object details |

### Invocation

| Command | Alias | Description |
|---------|-------|-------------|
| `Invoke-PowerStubCommand -Stub <name> -Command <cmd>` | `pstb` | Execute a command from a stub |

### Configuration Commands

| Command | Description |
|---------|-------------|
| `Get-PowerStubConfiguration` | View current configuration |
| `Import-PowerStubConfiguration` | Reload configuration from file |
| `Import-PowerStubConfiguration -Reset` | Reset to defaults |

### Feature Toggles

| Command | Description |
|---------|-------------|
| `Enable-PowerStubDraftCommands` | Show commands in `.draft` folders |
| `Disable-PowerStubDraftCommands` | Hide draft commands |
| `Enable-PowerStubBetaCommands` | Show commands in `.beta` folders |
| `Disable-PowerStubBetaCommands` | Hide beta commands |

## Configuration File

PowerStub stores its configuration in `PowerStub.json`:

```json
{
  "Stubs": {
    "DevOps": "C:\\Tools\\DevOps\\",
    "Database": "C:\\Tools\\Database\\"
  },
  "InvokeAlias": "pstb",
  "EnableFolder:Beta": false,
  "EnableFolder:Drafts": false
}
```

### Configuration Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `Stubs` | Object | `{}` | Map of stub names to root paths |
| `InvokeAlias` | String | `pstb` | Alias for `Invoke-PowerStubCommand` |
| `EnableFolder:Beta` | Boolean | `false` | Include `.beta` folder commands |
| `EnableFolder:Drafts` | Boolean | `false` | Include `.draft` folder commands |

## Command Lifecycle

PowerStub supports organizing commands by development stage:

```text
YourStub/
├── Commands/           # Production-ready commands (always visible)
│   └── deploy.ps1
├── .beta/              # Beta testing (Enable-PowerStubBetaCommands)
│   └── deploy-v2.ps1
├── .draft/             # Work in progress (Enable-PowerStubDraftCommands)
│   └── new-feature.ps1
└── .tests/             # Test files (not exposed as commands)
    └── deploy.tests.ps1
```

**Workflow:**

1. Start new commands in `.draft/`
2. Move to `.beta/` when ready for testing
3. Graduate to `Commands/` for production use

## Examples

### Register Multiple Stubs

```powershell
New-PowerStub -Name "DevOps" -Path "C:\Tools\DevOps"
New-PowerStub -Name "Database" -Path "C:\Tools\Database"
New-PowerStub -Name "Azure" -Path "C:\Tools\Azure"

# View all stubs
Get-PowerStubs
# Output:
# Name                           Value
# ----                           -----
# DevOps                         C:\Tools\DevOps\
# Database                       C:\Tools\Database\
# Azure                          C:\Tools\Azure\
```

### Work with Draft Commands

```powershell
# Enable draft visibility
Enable-PowerStubDraftCommands

# Now commands in .draft folders appear in completion
pstb DevOps <TAB>  # Shows both production and draft commands

# Disable when done developing
Disable-PowerStubDraftCommands
```

### Use with Executables

PowerStub works with `.exe` files too:

```powershell
# Place terraform.exe in your stub folder
# C:\Tools\DevOps\Commands\terraform.exe

# Use it through PowerStub
pstb DevOps terraform init
pstb DevOps terraform plan -out=tfplan
```

## Architecture

```text
PowerStub/                          # Repository root
├── PowerStub/                      # Module folder (publishable to PSGallery)
│   ├── Public/functions/           # Exported user-facing functions (11)
│   ├── Private/functions/          # Internal helper functions (10)
│   ├── Templates/                  # Command templates
│   ├── PowerStub.psm1              # Module loader
│   ├── PowerStub.psd1              # Module manifest
│   └── PowerStub.json              # Runtime configuration
├── tests/                          # Pester test files
├── README.md
├── CLAUDE.md                       # Development guide
└── LICENSE.txt                     # Apache 2.0
```

## Requirements

- PowerShell 5.1 or later
- Windows (primary support)

## License

Apache License 2.0 - See [LICENSE.txt](LICENSE.txt)

## Author

DevPossible LLC

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.
