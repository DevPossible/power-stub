# CLAUDE.md - PowerStub Development Guide

This file provides context for Claude Code when working on the PowerStub project.

## Project Overview

PowerStub is a PowerShell module that creates command proxies ("stubs") for organizing scripts and CLI tools. Instead of adding multiple directories to PATH, users register "stubs" that serve as namespaced entry points to their tools.

**Core concept:** `pstb <StubName> <CommandName> [arguments]`

## Repository Structure

```text
PowerStub/                        # Repository root
├── PowerStub/                    # Module directory (publishable to PSGallery)
│   ├── Public/functions/         # 11 exported user-facing functions
│   ├── Private/functions/        # 10 internal helper functions
│   ├── Templates/                # Command templates
│   ├── PowerStub.psm1            # Module loader (dot-sources all functions)
│   ├── PowerStub.psd1            # Module manifest (version 2.0)
│   └── PowerStub.json            # Runtime configuration
├── tests/                        # Pester test files (at repo root)
├── .claude/commands/             # Claude Code slash commands
├── README.md                     # User documentation
├── CLAUDE.md                     # This file
└── LICENSE.txt                   # Apache 2.0
```

## Key Files and Their Purposes

### Public Functions (User API)

| File | Function | Purpose |
|------|----------|---------|
| `Invoke-PowerStubCommand.ps1` | Main entry point | Executes commands via `pstb` alias |
| `New-PowerStub.ps1` | Registration | Creates new stub with folder structure |
| `Remove-PowerStub.ps1` | Cleanup | Unregisters a stub from config |
| `Get-PowerStubs.ps1` | Discovery | Lists all registered stubs |
| `Get-PowerStubCommand.ps1` | Introspection | Gets command object details |
| `Get-PowerStubConfiguration.ps1` | Config read | Returns current configuration |
| `Import-PowerStubConfiguration.ps1` | Config load | Loads/resets config from JSON |
| `Enable-PowerStubBetaCommands.ps1` | Toggle | Shows .beta folder commands |
| `Disable-PowerStubBetaCommands.ps1` | Toggle | Hides .beta folder commands |
| `Enable-PowerStubDraftCommands.ps1` | Toggle | Shows .draft folder commands |
| `Disable-PowerStubDraftCommands.ps1` | Toggle | Hides .draft folder commands |

### Private Functions (Internal)

| File | Function | Purpose |
|------|----------|---------|
| `Find-PowerStubCommands.ps1` | Discovery | Recursively finds .ps1/.exe files in stub |
| `Get-PowerStubCommandDynamicParams.ps1` | DynamicParam | Extracts parameters from target command |
| `Invoke-CheckedCommand.ps1` | Execution | Core command runner with error handling |
| `New-DynamicParam.ps1` | Utility | Creates RuntimeDefinedParameter objects |
| `ConvertTo-Hashtable.ps1` | Utility | Converts PSObjects to hashtables |
| `Get-PowerStubConfigurationDefaults.ps1` | Config | Returns default config structure |
| `Get-PowerStubConfigurationKey.ps1` | Config | Gets single config value |
| `Set-PowerStubConfigurationKey.ps1` | Config | Sets single config key |
| `Set-PowerStubConfiguration.ps1` | Config | Sets entire config object |
| `Export-PowerStubConfiguration.ps1` | Config | Saves config to PowerStub.json |

## Architecture Patterns

### Module Loading (PowerStub.psm1)

1. Discovers all `.ps1` files in `Public/functions/` and `Private/functions/`
2. Dot-sources each file to load functions into module scope
3. Loads configuration defaults, then imports `PowerStub.json`
4. Exports only public functions
5. Creates `pstb` alias for `Invoke-PowerStubCommand`
6. Registers ArgumentCompleters for `-Stub` and `-Command` parameters

### Dynamic Parameters

`Invoke-PowerStubCommand` uses `DynamicParam {}` to introspect the target command and expose its parameters. This enables:

- Tab completion for target command parameters
- Parameter validation passthrough
- Help text inheritance

### Configuration Management

- Config stored in `$Script:PSTBSettings` hashtable
- Persisted to `PowerStub.json` (excludes internal keys)
- Internal keys: `ModulePath`, `ConfigFile`, `InternalConfigKeys`

## Build & Test Commands

```powershell
# Import module for development
Import-Module ./PowerStub/PowerStub.psm1 -Force

# Run Pester tests
Invoke-Pester ./tests/

# View current configuration
Get-PowerStubConfiguration

# Reset configuration to defaults
Import-PowerStubConfiguration -Reset
```

## Common Development Tasks

### Adding a New Public Function

1. Create file in `PowerStub/Public/functions/`
2. Follow naming convention: `Verb-PowerStub*.ps1`
3. Function is auto-exported via module loader

### Adding a New Private Function

1. Create file in `PowerStub/Private/functions/`
2. Function is auto-loaded but not exported

### Adding New Configuration Keys

1. Add default value in `Get-PowerStubConfigurationDefaults.ps1`
2. If internal-only, add to `InternalConfigKeys` array
3. Use `Set-PowerStubConfigurationKey` to modify at runtime

## Known Issues / TODO

- `Get-NamedParameters` function is referenced in `Invoke-CheckedCommand.ps1` but not defined - this breaks object parameter splatting
- The module currently uses 40 positional parameters (o1-o40) as a workaround for argument passing

## Code Style Guidelines

- Use approved PowerShell verbs (Get-, Set-, New-, Remove-, Enable-, Disable-, Invoke-, Import-, Export-)
- Prefix all public functions with `PowerStub` (e.g., `Get-PowerStubs`)
- Use `$Script:` scope for module-level variables
- Include `[CmdletBinding()]` on all functions
- Use argument completers for better UX

## Testing Approach

Tests use Pester framework. Key test areas:

- Configuration loading/saving
- Stub registration/removal
- Alias creation
- Module exports
- Folder structure creation

## Claude Commands

Custom slash commands available in `.claude/commands/`:

| Command | Purpose |
|---------|---------|
| `/new-command <stub> <name> [desc]` | Create a new command script in a stub |
| `/test` | Run Pester tests for the module |
| `/debug-config` | Diagnose configuration issues |
| `/add-function <scope> <name> [desc]` | Add a new module function (public/private) |
| `/list-commands [stub]` | List all commands in a stub |

## Recommended Sub-Agents

When working on this codebase, consider using these specialized agents:

### For Exploration Tasks

Use the **Explore** agent for:

- Understanding how dynamic parameters flow through the system
- Finding all places where configuration is read/written
- Tracing command execution path from `pstb` to actual script

### For Implementation Planning

Use the **Plan** agent for:

- Adding new features like additional file type support (.bat, .cmd)
- Implementing the missing `Get-NamedParameters` function
- Redesigning the argument passing mechanism

## PowerShell-Specific Tips

### Testing Commands Interactively

```powershell
# Reload module after changes
Import-Module ./PowerStub/PowerStub.psm1 -Force

# Test tab completion
pstb <Tab>                    # Should list stubs
pstb DevOps <Tab>            # Should list commands in DevOps
pstb DevOps deploy -<Tab>    # Should list command parameters
```

### Debugging Dynamic Parameters

```powershell
# Get the command object to inspect parameters
$cmd = Get-PowerStubCommand -Stub "StubName" -Command "CommandName"
$cmd.Parameters.Keys

# Or inspect directly
Get-Command "path/to/script.ps1" | Select-Object -ExpandProperty Parameters
```

### Common Pitfalls

1. **Module scope variables**: Use `$Script:` prefix for module-level state
2. **ArgumentCompleter registration**: Must happen after module loads
3. **Dynamic parameter timing**: `DynamicParam {}` runs before `begin {}` block
4. **Exit code handling**: `.exe` files set `$LASTEXITCODE`, scripts may not
