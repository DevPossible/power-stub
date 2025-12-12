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
- **Lifecycle Prefixes**: Built-in support for `alpha.*` and `beta.*` command stages
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
├── Commands\       # Your commands go here
└── .tests\         # Test files
```

### 2. Add Commands

Place your scripts or executables in the `Commands` folder:

```powershell
# C:\Tools\DevOps\Commands\deploy-app.ps1
param(
    [Parameter(Mandatory)]
    [string]$Environment,

    [string]$Version = "latest"
)

Write-Host "Deploying to $Environment with version $Version"
```

#### Complex Commands with Supporting Files

For commands that need helper scripts, data files, or executables, create a subfolder with the command name. Only the file matching the folder name is exposed as a command:

```text
Commands/
├── simple-task.ps1              # Exposed as "simple-task"
├── quick-deploy.exe             # Exposed as "quick-deploy"
└── complex-deploy/              # Subfolder for complex command
    ├── complex-deploy.ps1       # Exposed as "complex-deploy"
    ├── deploy-helper.ps1        # NOT exposed (helper script)
    ├── config.json              # NOT exposed (data file)
    └── validator.exe            # NOT exposed (helper executable)
```

This prevents helper scripts from appearing in tab completion or being accidentally invoked as commands.

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
| `Enable-PowerStubAlphaCommands` | Show `alpha.*` prefixed commands |
| `Disable-PowerStubAlphaCommands` | Hide alpha commands |
| `Enable-PowerStubBetaCommands` | Show `beta.*` prefixed commands |
| `Disable-PowerStubBetaCommands` | Hide beta commands |

## Configuration File

PowerStub stores its configuration in `PowerStub.json`, located in the module directory (alongside `PowerStub.psm1`):

```json
{
  "Stubs": {
    "DevOps": "C:\\Tools\\DevOps\\",
    "Database": "C:\\Tools\\Database\\"
  },
  "InvokeAlias": "pstb",
  "EnablePrefix:Alpha": false,
  "EnablePrefix:Beta": false
}
```

### Configuration Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `Stubs` | Object | `{}` | Map of stub names to root paths |
| `InvokeAlias` | String | `pstb` | Alias for `Invoke-PowerStubCommand` |
| `EnablePrefix:Alpha` | Boolean | `false` | Include `alpha.*` prefixed commands |
| `EnablePrefix:Beta` | Boolean | `false` | Include `beta.*` prefixed commands |

## Command Lifecycle

PowerStub supports organizing commands by development stage using filename prefixes:

```text
YourStub/Commands/
├── alpha.new-feature.ps1   # Work in progress (Enable-PowerStubAlphaCommands)
├── beta.deploy-v2.ps1      # Beta testing (Enable-PowerStubBetaCommands)
├── deploy.ps1              # Production-ready (always visible)
└── complex-task/           # Subfolder for complex command
    ├── alpha.complex-task.ps1   # Alpha version (file matches folder name)
    └── complex-task.ps1         # Production version
```

**Prefix conventions:**

- `alpha.*` - Work-in-progress commands (developer mode)
- `beta.*` - Beta/experimental commands (tester mode)
- No prefix - Production-ready commands

**Workflow:**

1. Create new commands with `alpha.` prefix (e.g., `alpha.my-feature.ps1`)
2. Rename to `beta.` prefix when ready for testing
3. Remove prefix for production use

**Resolution precedence:** `alpha.*` → `beta.*` → production (no prefix)

When multiple versions exist (e.g., `alpha.deploy.ps1`, `beta.deploy.ps1`, `deploy.ps1`),
the command resolves in precedence order based on enabled modes. This applies to both direct files and files in subfolders.

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

### Work with Alpha Commands

```powershell
# Enable alpha visibility
Enable-PowerStubAlphaCommands

# Now alpha.* prefixed commands appear in completion
pstb DevOps <TAB>  # Shows both production and alpha commands

# Run an alpha command (no need to type the prefix)
pstb DevOps my-feature  # Executes alpha.my-feature.ps1

# Disable when done developing
Disable-PowerStubAlphaCommands
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
│   ├── PowerStub.tests.ps1         # Main test suite
│   └── sample_stub_root/           # Sample stub for integration tests
├── dev-reload.ps1                  # Reload module for local testing
├── dev-test.ps1                    # Run Pester test suite
├── README.md
├── CLAUDE.md                       # Development guide for Claude Code
└── LICENSE.txt                     # Apache 2.0
```

## Development

This section covers local development and testing of the PowerStub module.

### Prerequisites

- PowerShell 5.1 or later
- [Pester](https://pester.dev/) v5.x or later for running tests

```powershell
# Install Pester if not already installed
Install-Module Pester -Force -SkipPublisherCheck
```

### Local Development Workflow

#### 1. Clone and Set Up

```powershell
git clone https://github.com/DevPossible/PowerStub.git
cd PowerStub
```

#### 2. Load the Module for Testing

Use the `dev-reload.ps1` script to import the module from source:

```powershell
# Load/reload the module
.\dev-reload.ps1

# Load and reset configuration to defaults
.\dev-reload.ps1 -Reset
```

This script:

- Removes any existing PowerStub module from the session
- Imports the module from local source (`PowerStub/PowerStub.psm1`)
- Shows module info and current configuration

#### 3. Make Changes

Edit files in the `PowerStub/` folder:

- **Public functions**: `PowerStub/Public/functions/` - Exported to users
- **Private functions**: `PowerStub/Private/functions/` - Internal helpers

After making changes, reload the module to test:

```powershell
.\dev-reload.ps1
```

#### 4. Run Tests

Use the `dev-test.ps1` script to run the Pester test suite:

```powershell
# Run all tests with detailed output
.\dev-test.ps1

# Run specific tests by name filter
.\dev-test.ps1 -Filter "*Alpha*"

# Run with minimal output
.\dev-test.ps1 -Output Normal

# Skip module reload (if already loaded)
.\dev-test.ps1 -SkipReload
```

#### 5. Interactive Testing

Test your changes interactively using the sample stub:

```powershell
# Reload module
.\dev-reload.ps1 -Reset

# Register the sample stub from tests
New-PowerStub -Name "Sample" -Path ".\tests\sample_stub_root" -Force

# Test command discovery
Get-PowerStubCommand -Stub "Sample" -Command "deploy"

# Test command execution
pstb Sample deploy -Environment "test"

# Test alpha/beta features
Enable-PowerStubAlphaCommands
pstb Sample new-feature -Name "MyFeature"
Disable-PowerStubAlphaCommands
```

### Test Structure

Tests are located in `tests/PowerStub.tests.ps1` and cover:

| Area | Description |
|------|-------------|
| Module Loading | Exports, aliases, private function isolation |
| Configuration | Get/set/reset configuration values |
| Stub Management | Register, remove, list stubs |
| Command Discovery | Direct files, subfolders, helper isolation |
| Alpha/Beta Prefixes | Enable/disable, precedence order |
| Command Execution | Parameter passing, output capture |

The `tests/sample_stub_root/` folder contains a pre-configured stub with various command types for integration testing.

### Adding New Features

1. **New public function**: Create in `PowerStub/Public/functions/Verb-PowerStub*.ps1`
2. **New private function**: Create in `PowerStub/Private/functions/*.ps1`
3. **Add tests**: Update `tests/PowerStub.tests.ps1`
4. **Update documentation**: Update README.md and CLAUDE.md

Functions are automatically loaded by the module - no manifest changes needed.

### Code Style

- Use approved PowerShell verbs (`Get-`, `Set-`, `New-`, etc.)
- Prefix public functions with `PowerStub`
- Include `[CmdletBinding()]` on all functions
- Use `$Script:` scope for module-level variables

## Requirements

- PowerShell 5.1 or later
- Windows (primary support)

## License

Apache License 2.0 - See [LICENSE.txt](LICENSE.txt)

## Author

DevPossible LLC

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

See the [Development](#development) section above for local setup, testing, and code style guidelines.
