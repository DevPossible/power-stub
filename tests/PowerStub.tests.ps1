#Requires -Modules Pester
<#
.SYNOPSIS
    Comprehensive test suite for the PowerStub module.

.DESCRIPTION
    Tests cover:
    - Module loading and exports
    - Configuration management
    - Stub registration and removal
    - Command discovery (direct files and subfolders)
    - Alpha/Beta prefix system
    - Command execution

.NOTES
    Run with: Invoke-Pester ./tests/PowerStub.tests.ps1
#>

BeforeAll {
    # Remove any existing module
    $module = Get-Module -Name 'PowerStub'
    if ($module) {
        Remove-Module -ModuleInfo $module -Force
    }

    # Import the module
    $modulePath = Join-Path $PSScriptRoot '..\PowerStub\PowerStub.psm1'
    Import-Module $modulePath -Force

    # Store original config for restoration
    $script:OriginalConfig = Get-PowerStubConfiguration
    $script:ConfigFile = $script:OriginalConfig['ConfigFile']
    $script:ConfigBackup = $script:ConfigFile + ".test.bak"

    # Backup config if it exists
    if (Test-Path $script:ConfigFile) {
        Copy-Item $script:ConfigFile $script:ConfigBackup -Force
    }

    # Sample stub root for integration tests
    $script:SampleStubRoot = Join-Path $PSScriptRoot 'sample_stub_root'
}

AfterAll {
    # Restore original config
    if (Test-Path $script:ConfigBackup) {
        Copy-Item $script:ConfigBackup $script:ConfigFile -Force
        Remove-Item $script:ConfigBackup -Force
    }
    Import-PowerStubConfiguration
}

Describe "PowerStub Module" {
    Context "Module Loading" {
        It "Should import the module successfully" {
            $module = Get-Module -Name 'PowerStub'
            $module | Should -Not -BeNullOrEmpty
        }

        It "Should export the expected public functions" {
            $expectedFunctions = @(
                'Invoke-PowerStubCommand'
                'New-PowerStub'
                'New-PowerStubDirectAlias'
                'Remove-PowerStubDirectAlias'
                'Remove-PowerStub'
                'Get-PowerStubs'
                'Get-PowerStubCommand'
                'Get-PowerStubConfiguration'
                'Import-PowerStubConfiguration'
                'Enable-PowerStubAlphaCommands'
                'Disable-PowerStubAlphaCommands'
                'Enable-PowerStubBetaCommands'
                'Disable-PowerStubBetaCommands'
            )

            foreach ($func in $expectedFunctions) {
                Get-Command -Module PowerStub -Name $func -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Function '$func' should be exported"
            }
        }

        It "Should create the 'pstb' alias" {
            $alias = Get-Alias -Name 'pstb' -ErrorAction SilentlyContinue
            $alias | Should -Not -BeNullOrEmpty
            $alias.Definition | Should -Be 'Invoke-PowerStubCommand'
        }

        It "Should not export private functions" {
            $privateFunctions = @(
                'Find-PowerStubCommands'
                'Get-PowerStubCommandDynamicParams'
                'Invoke-CheckedCommand'
                'New-DynamicParam'
                'ConvertTo-Hashtable'
                'Get-PowerStubConfigurationDefaults'
                'Get-PowerStubConfigurationKey'
                'Set-PowerStubConfigurationKey'
                'Set-PowerStubConfiguration'
                'Export-PowerStubConfiguration'
            )

            foreach ($func in $privateFunctions) {
                $cmd = Get-Command -Module PowerStub -Name $func -ErrorAction SilentlyContinue
                $cmd | Should -BeNullOrEmpty -Because "Function '$func' should not be exported"
            }
        }
    }
}

Describe "Configuration Management" {
    BeforeAll {
        # Reset to clean state
        Import-PowerStubConfiguration -Reset
    }

    Context "Get-PowerStubConfiguration" {
        It "Should return a hashtable" {
            $config = Get-PowerStubConfiguration
            $config | Should -BeOfType [hashtable]
        }

        It "Should contain required keys" {
            $config = Get-PowerStubConfiguration
            $config.Keys | Should -Contain 'Stubs'
            $config.Keys | Should -Contain 'InvokeAlias'
            $config.Keys | Should -Contain 'ModulePath'
            $config.Keys | Should -Contain 'ConfigFile'
        }

        It "Should return default values after reset" {
            Import-PowerStubConfiguration -Reset
            $config = Get-PowerStubConfiguration
            $config['InvokeAlias'] | Should -Be 'pstb'
            $config['EnablePrefix:Alpha'] | Should -Be $false
            $config['EnablePrefix:Beta'] | Should -Be $false
        }

        It "Should return a specific key when requested" {
            $alias = Get-PowerStubConfiguration 'InvokeAlias'
            $alias | Should -Be 'pstb'
        }
    }

    Context "Import-PowerStubConfiguration" {
        It "Should reset configuration with -Reset flag" {
            Import-PowerStubConfiguration -Reset
            $config = Get-PowerStubConfiguration
            $config['Stubs'].Keys.Count | Should -Be 0
        }

        It "Should reload configuration from file" {
            # This tests that Import-PowerStubConfiguration reads from file
            Import-PowerStubConfiguration
            $config = Get-PowerStubConfiguration
            $config | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Stub Management" {
    BeforeEach {
        # Reset config before each test
        Import-PowerStubConfiguration -Reset
    }

    Context "New-PowerStub" {
        It "Should register a new stub" {
            $testPath = Join-Path $env:TEMP "PowerStubTest_$(Get-Random)"

            try {
                New-PowerStub -Name "TestStub" -Path $testPath

                $stubs = Get-PowerStubs
                $stubs.Keys | Should -Contain "TestStub"
                $stubs["TestStub"] | Should -Be $testPath
            }
            finally {
                if (Test-Path $testPath) {
                    Remove-Item $testPath -Recurse -Force
                }
            }
        }

        It "Should create the folder structure" {
            $testPath = Join-Path $env:TEMP "PowerStubTest_$(Get-Random)"

            try {
                New-PowerStub -Name "TestStub" -Path $testPath

                Test-Path $testPath | Should -Be $true
                Test-Path (Join-Path $testPath 'Commands') | Should -Be $true
                Test-Path (Join-Path $testPath '.tests') | Should -Be $true
            }
            finally {
                if (Test-Path $testPath) {
                    Remove-Item $testPath -Recurse -Force
                }
            }
        }

        It "Should throw when stub already exists without -Force" {
            $testPath = Join-Path $env:TEMP "PowerStubTest_$(Get-Random)"

            try {
                New-PowerStub -Name "TestStub" -Path $testPath
                { New-PowerStub -Name "TestStub" -Path $testPath } | Should -Throw
            }
            finally {
                if (Test-Path $testPath) {
                    Remove-Item $testPath -Recurse -Force
                }
            }
        }

        It "Should overwrite when -Force is specified" {
            $testPath1 = Join-Path $env:TEMP "PowerStubTest_$(Get-Random)"
            $testPath2 = Join-Path $env:TEMP "PowerStubTest_$(Get-Random)"

            try {
                New-PowerStub -Name "TestStub" -Path $testPath1
                New-PowerStub -Name "TestStub" -Path $testPath2 -Force

                $stubs = Get-PowerStubs
                $stubs["TestStub"] | Should -Be $testPath2
            }
            finally {
                if (Test-Path $testPath1) { Remove-Item $testPath1 -Recurse -Force }
                if (Test-Path $testPath2) { Remove-Item $testPath2 -Recurse -Force }
            }
        }

        It "Should persist configuration to file" {
            $testPath = Join-Path $env:TEMP "PowerStubTest_$(Get-Random)"

            try {
                New-PowerStub -Name "TestStub" -Path $testPath

                $configFile = (Get-PowerStubConfiguration)['ConfigFile']
                Test-Path $configFile | Should -Be $true
            }
            finally {
                if (Test-Path $testPath) {
                    Remove-Item $testPath -Recurse -Force
                }
            }
        }
    }

    Context "Remove-PowerStub" {
        It "Should remove a registered stub" {
            $testPath = Join-Path $env:TEMP "PowerStubTest_$(Get-Random)"

            try {
                New-PowerStub -Name "TestStub" -Path $testPath
                Remove-PowerStub -Name "TestStub"

                $stubs = Get-PowerStubs
                $stubs.Keys | Should -Not -Contain "TestStub"
            }
            finally {
                if (Test-Path $testPath) {
                    Remove-Item $testPath -Recurse -Force
                }
            }
        }

        It "Should not delete the folder (files remain)" {
            $testPath = Join-Path $env:TEMP "PowerStubTest_$(Get-Random)"

            try {
                New-PowerStub -Name "TestStub" -Path $testPath
                Remove-PowerStub -Name "TestStub"

                # Folder should still exist
                Test-Path $testPath | Should -Be $true
            }
            finally {
                if (Test-Path $testPath) {
                    Remove-Item $testPath -Recurse -Force
                }
            }
        }
    }

    Context "Get-PowerStubs" {
        It "Should return empty hashtable when no stubs registered" {
            Import-PowerStubConfiguration -Reset
            $stubs = Get-PowerStubs
            $stubs | Should -BeOfType [hashtable]
            $stubs.Keys.Count | Should -Be 0
        }

        It "Should return all registered stubs" {
            $testPath1 = Join-Path $env:TEMP "PowerStubTest1_$(Get-Random)"
            $testPath2 = Join-Path $env:TEMP "PowerStubTest2_$(Get-Random)"

            try {
                New-PowerStub -Name "Stub1" -Path $testPath1
                New-PowerStub -Name "Stub2" -Path $testPath2

                $stubs = Get-PowerStubs
                $stubs.Keys.Count | Should -Be 2
                $stubs.Keys | Should -Contain "Stub1"
                $stubs.Keys | Should -Contain "Stub2"
            }
            finally {
                if (Test-Path $testPath1) { Remove-Item $testPath1 -Recurse -Force }
                if (Test-Path $testPath2) { Remove-Item $testPath2 -Recurse -Force }
            }
        }
    }
}

Describe "Command Discovery" {
    BeforeAll {
        # Register the sample stub for testing
        Import-PowerStubConfiguration -Reset
        New-PowerStub -Name "SampleStub" -Path $script:SampleStubRoot -Force
    }

    Context "Direct Commands" {
        BeforeEach {
            # Ensure alpha/beta are disabled
            Disable-PowerStubAlphaCommands
            Disable-PowerStubBetaCommands
        }

        It "Should discover direct .ps1 files in Commands folder" {
            $cmd = Get-PowerStubCommand -Stub "SampleStub" -Command "get-data"
            $cmd | Should -Not -BeNullOrEmpty
            $cmd.Name | Should -Match "get-data\.ps1$"
        }

        It "Should discover multiple direct commands" {
            $cmd1 = Get-PowerStubCommand -Stub "SampleStub" -Command "get-data"
            $cmd2 = Get-PowerStubCommand -Stub "SampleStub" -Command "new-data"

            $cmd1 | Should -Not -BeNullOrEmpty
            $cmd2 | Should -Not -BeNullOrEmpty
        }
    }

    Context "Subfolder Commands" {
        BeforeEach {
            Disable-PowerStubAlphaCommands
            Disable-PowerStubBetaCommands
        }

        It "Should discover commands in subfolders matching folder name" {
            $cmd = Get-PowerStubCommand -Stub "SampleStub" -Command "remove-data"
            $cmd | Should -Not -BeNullOrEmpty
            $cmd.Name | Should -Match "remove-data\.ps1$"
        }

        It "Should NOT discover helper scripts in subfolders" {
            # helper.ps1 exists in remove-data folder but shouldn't be exposed
            $cmd = Get-PowerStubCommand -Stub "SampleStub" -Command "helper"
            $cmd | Should -BeNullOrEmpty
        }
    }

    Context "Non-existent Commands" {
        It "Should return null for non-existent command" {
            $cmd = Get-PowerStubCommand -Stub "SampleStub" -Command "nonexistent"
            $cmd | Should -BeNullOrEmpty
        }

        It "Should warn for non-existent stub" {
            # Capture warning stream (stream 3)
            $result = Get-PowerStubCommand -Stub "NonExistentStub" -Command "test" 3>&1
            $warnings = $result | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }
            $warnings | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Alpha/Beta Prefix System" {
    BeforeAll {
        Import-PowerStubConfiguration -Reset
        New-PowerStub -Name "SampleStub" -Path $script:SampleStubRoot -Force
    }

    Context "Enable/Disable Alpha Commands" {
        It "Should enable alpha commands" {
            Enable-PowerStubAlphaCommands
            $config = Get-PowerStubConfiguration
            $config['EnablePrefix:Alpha'] | Should -Be $true
        }

        It "Should disable alpha commands" {
            Disable-PowerStubAlphaCommands
            $config = Get-PowerStubConfiguration
            $config['EnablePrefix:Alpha'] | Should -Be $false
        }
    }

    Context "Enable/Disable Beta Commands" {
        It "Should enable beta commands" {
            Enable-PowerStubBetaCommands
            $config = Get-PowerStubConfiguration
            $config['EnablePrefix:Beta'] | Should -Be $true
        }

        It "Should disable beta commands" {
            Disable-PowerStubBetaCommands
            $config = Get-PowerStubConfiguration
            $config['EnablePrefix:Beta'] | Should -Be $false
        }
    }

    Context "Alpha Command Discovery" {
        It "Should NOT discover alpha commands when disabled" {
            Disable-PowerStubAlphaCommands
            $cmd = Get-PowerStubCommand -Stub "SampleStub" -Command "new-feature"
            $cmd | Should -BeNullOrEmpty
        }

        It "Should discover alpha commands when enabled" {
            Enable-PowerStubAlphaCommands
            $cmd = Get-PowerStubCommand -Stub "SampleStub" -Command "new-feature"
            $cmd | Should -Not -BeNullOrEmpty
            $cmd.Name | Should -Match "alpha\.new-feature\.ps1$"
        }
    }

    Context "Beta Command Discovery" {
        BeforeEach {
            Disable-PowerStubAlphaCommands
        }

        It "Should NOT discover beta commands when disabled" {
            Disable-PowerStubBetaCommands
            # deploy has both beta and production versions
            $cmd = Get-PowerStubCommand -Stub "SampleStub" -Command "deploy"
            $cmd | Should -Not -BeNullOrEmpty
            # Should get production version, not beta
            $cmd.Name | Should -Match "^deploy\.ps1$"
        }

        It "Should discover beta commands when enabled" {
            Enable-PowerStubBetaCommands
            $cmd = Get-PowerStubCommand -Stub "SampleStub" -Command "deploy"
            $cmd | Should -Not -BeNullOrEmpty
            # Should get beta version
            $cmd.Name | Should -Match "beta\.deploy\.ps1$"
        }
    }

    Context "Precedence Order (alpha -> beta -> production)" {
        It "Alpha should take precedence over beta and production" {
            Enable-PowerStubAlphaCommands
            Enable-PowerStubBetaCommands

            # remove-data has alpha and production versions in subfolder
            $cmd = Get-PowerStubCommand -Stub "SampleStub" -Command "remove-data"
            $cmd | Should -Not -BeNullOrEmpty
            $cmd.Name | Should -Match "alpha\.remove-data\.ps1$"
        }

        It "Beta should take precedence over production (when alpha disabled)" {
            Disable-PowerStubAlphaCommands
            Enable-PowerStubBetaCommands

            # deploy has beta and production versions
            $cmd = Get-PowerStubCommand -Stub "SampleStub" -Command "deploy"
            $cmd | Should -Not -BeNullOrEmpty
            $cmd.Name | Should -Match "beta\.deploy\.ps1$"
        }

        It "Production should be used when alpha and beta disabled" {
            Disable-PowerStubAlphaCommands
            Disable-PowerStubBetaCommands

            $cmd = Get-PowerStubCommand -Stub "SampleStub" -Command "deploy"
            $cmd | Should -Not -BeNullOrEmpty
            $cmd.Name | Should -Match "^deploy\.ps1$"
        }
    }

    Context "Subfolder Alpha/Beta Commands" {
        It "Should discover alpha commands in subfolders" {
            Enable-PowerStubAlphaCommands

            $cmd = Get-PowerStubCommand -Stub "SampleStub" -Command "remove-data"
            $cmd | Should -Not -BeNullOrEmpty
            $cmd.Name | Should -Match "alpha\.remove-data\.ps1$"
        }

        It "Should fall back to production in subfolder when alpha disabled" {
            Disable-PowerStubAlphaCommands
            Disable-PowerStubBetaCommands

            $cmd = Get-PowerStubCommand -Stub "SampleStub" -Command "remove-data"
            $cmd | Should -Not -BeNullOrEmpty
            $cmd.Name | Should -Match "^remove-data\.ps1$"
        }
    }
}

Describe "Command Execution" {
    BeforeAll {
        Import-PowerStubConfiguration -Reset
        New-PowerStub -Name "SampleStub" -Path $script:SampleStubRoot -Force
        Disable-PowerStubAlphaCommands
        Disable-PowerStubBetaCommands
    }

    Context "Basic Execution" {
        It "Should execute a command and return output" {
            $output = pstb SampleStub deploy -Environment "test"
            $output | Should -Not -BeNullOrEmpty
            $output | Should -Contain "deploy.ps1 (production) executed"
        }
    }

    Context "Parameter Passing" {
        It "Should pass string parameters correctly" {
            $output = pstb SampleStub deploy -Environment "production" -Version "1.0.0"
            $output | Should -Contain "Environment: production"
            $output | Should -Contain "Version: 1.0.0"
        }
    }

    Context "Alpha/Beta Command Execution" {
        It "Should execute alpha command when enabled" {
            Enable-PowerStubAlphaCommands

            $output = pstb SampleStub new-feature -Name "TestFeature"
            $output | Should -Contain "alpha.new-feature.ps1 executed"
            $output | Should -Contain "Name: TestFeature"

            Disable-PowerStubAlphaCommands
        }

        It "Should execute beta command when enabled" {
            Disable-PowerStubAlphaCommands
            Enable-PowerStubBetaCommands

            $output = pstb SampleStub deploy -Environment "staging"
            $output | Should -Contain "beta.deploy.ps1 executed"
            $output | Should -Contain "Environment: staging"

            Disable-PowerStubBetaCommands
        }
    }
}

Describe "Dynamic Parameters and Tab Completion" {
    BeforeAll {
        Import-PowerStubConfiguration -Reset
        New-PowerStub -Name "SampleStub" -Path $script:SampleStubRoot -Force
        Disable-PowerStubAlphaCommands
        Disable-PowerStubBetaCommands
    }

    Context "Get-PowerStubCommandDynamicParams (via InModuleScope)" {
        It "Should return empty dictionary when stub is missing" {
            $result = InModuleScope PowerStub {
                Get-PowerStubCommandDynamicParams -stub "" -command "test"
            }
            $result | Should -BeOfType [System.Management.Automation.RuntimeDefinedParameterDictionary]
            $result.Count | Should -Be 0
        }

        It "Should return empty dictionary when command is missing" {
            $result = InModuleScope PowerStub {
                Get-PowerStubCommandDynamicParams -stub "SampleStub" -command ""
            }
            $result | Should -BeOfType [System.Management.Automation.RuntimeDefinedParameterDictionary]
            $result.Count | Should -Be 0
        }

        It "Should return parameters for valid command" {
            $result = InModuleScope PowerStub {
                Get-PowerStubCommandDynamicParams -stub "SampleStub" -command "deploy"
            }
            $result | Should -BeOfType [System.Management.Automation.RuntimeDefinedParameterDictionary]
            $result.Count | Should -BeGreaterThan 0
            $result.Keys | Should -Contain "Environment"
            $result.Keys | Should -Contain "Version"
        }

        It "Should return empty dictionary for non-existent command (no warning)" {
            # This tests that tab completion doesn't spam warnings
            $result = InModuleScope PowerStub {
                Get-PowerStubCommandDynamicParams -stub "SampleStub" -command "nonexistent" -WarningAction SilentlyContinue
            }
            $result | Should -BeOfType [System.Management.Automation.RuntimeDefinedParameterDictionary]
            $result.Count | Should -Be 0
        }
    }

    Context "Argument Completers" {
        It "Should complete stub names" {
            # Test the stub completer directly
            $completions = InModuleScope PowerStub {
                $stubs = Get-PowerStubConfigurationKey 'Stubs'
                @($stubs.Keys | Where-Object { $_ -like "Sample*" })
            }
            $completions | Should -Contain "SampleStub"
        }

        It "Should complete command names (stripping prefixes)" {
            Enable-PowerStubAlphaCommands
            Enable-PowerStubBetaCommands

            # Simulate command completer behavior
            $commands = InModuleScope PowerStub {
                $commands = @(Find-PowerStubCommands "SampleStub")
                @($commands | ForEach-Object {
                    $name = $_.BaseName
                    if ($name -match '^(alpha|beta)\.(.+)$') {
                        $Matches[2]
                    } else {
                        $name
                    }
                } | Select-Object -Unique)
            }

            # Should have unprefixed names
            $commands | Should -Contain "deploy"
            $commands | Should -Contain "new-feature"
            # Should NOT have prefixed names
            $commands | Should -Not -Contain "alpha.new-feature"
            $commands | Should -Not -Contain "beta.deploy"

            Disable-PowerStubAlphaCommands
            Disable-PowerStubBetaCommands
        }
    }

    Context "Invoke-PowerStubCommand Base Functionality" {
        It "Should expose Invoke-PowerStubCommand" {
            $cmd = Get-Command -Name 'Invoke-PowerStubCommand'
            $cmd | Should -Not -BeNullOrEmpty
        }

        It "Should have Stub and Command as static parameters" {
            $cmd = Get-Command -Name 'Invoke-PowerStubCommand'
            $cmd.Parameters.Keys | Should -Contain 'Stub'
            $cmd.Parameters.Keys | Should -Contain 'Command'
        }
    }

    Context "Tab Completion for Dynamic Parameters" {
        It "Should include dynamic parameters in tab completion" {
            # Use CompleteInput to simulate tab completion
            $input = 'Invoke-PowerStubCommand -Stub SampleStub -Command deploy -'
            $completions = [System.Management.Automation.CommandCompletion]::CompleteInput($input, $input.Length, $null)

            $completionTexts = @($completions.CompletionMatches | Select-Object -ExpandProperty CompletionText)

            # Should include the dynamic parameter from the deploy command
            $completionTexts | Should -Contain '-Environment'
        }

        It "Should include dynamic parameters when using alias" {
            $input = 'pstb SampleStub deploy -'
            $completions = [System.Management.Automation.CommandCompletion]::CompleteInput($input, $input.Length, $null)

            $completionTexts = @($completions.CompletionMatches | Select-Object -ExpandProperty CompletionText)

            # Should include the dynamic parameter from the deploy command
            $completionTexts | Should -Contain '-Environment'
        }

        It "Should not break other commands completion" {
            $input = 'Get-ChildItem -'
            $completions = [System.Management.Automation.CommandCompletion]::CompleteInput($input, $input.Length, $null)

            $completionTexts = @($completions.CompletionMatches | Select-Object -ExpandProperty CompletionText)

            # Should still work normally for other commands
            $completionTexts | Should -Contain '-Path'
        }
    }
}

Describe "New-PowerStubDirectAlias" {
    BeforeAll {
        Import-PowerStubConfiguration -Reset
        New-PowerStub -Name "SampleStub" -Path $script:SampleStubRoot -Force
    }

    BeforeEach {
        # Clean up any test aliases thoroughly
        @('teststub', 'ts', 'myalias', 'forcealias', 'configalias') | ForEach-Object {
            # Remove from function: drive
            Remove-Item "function:$_" -ErrorAction SilentlyContinue
            Remove-Item "function:global:$_" -ErrorAction SilentlyContinue
        }
        # Clear direct aliases from config
        InModuleScope PowerStub { Set-PowerStubConfigurationKey 'DirectAliases' @{} }
    }

    AfterAll {
        # Clean up test aliases
        @('teststub', 'ts', 'myalias', 'forcealias', 'configalias') | ForEach-Object {
            Remove-Item "function:$_" -ErrorAction SilentlyContinue
            Remove-Item "function:global:$_" -ErrorAction SilentlyContinue
        }
    }

    Context "Parameter Validation" {
        It "Should require -AliasName parameter" {
            { New-PowerStubDirectAlias -Stub "SampleStub" } | Should -Throw
        }

        It "Should require -Stub parameter" {
            { New-PowerStubDirectAlias -AliasName "ts" } | Should -Throw
        }

        It "Should throw when stub doesn't exist" {
            { New-PowerStubDirectAlias -AliasName "ts" -Stub "NonExistentStub" } | Should -Throw "*not found*"
        }

        It "Should validate alias name format" {
            { New-PowerStubDirectAlias -AliasName "123invalid" -Stub "SampleStub" } | Should -Throw
        }

        It "Should throw when alias exists without -Force" {
            New-PowerStubDirectAlias -AliasName "ts" -Stub "SampleStub"
            { New-PowerStubDirectAlias -AliasName "ts" -Stub "SampleStub" } | Should -Throw "*already exists*"
        }
    }

    Context "Alias Creation" {
        It "Should create a global function with the alias name" {
            New-PowerStubDirectAlias -AliasName "teststub" -Stub "SampleStub"

            $cmd = Get-Command "teststub" -ErrorAction SilentlyContinue
            $cmd | Should -Not -BeNullOrEmpty
            $cmd.CommandType | Should -Be 'Function'
        }

        It "Should overwrite alias when -Force is specified" {
            New-PowerStubDirectAlias -AliasName "forcealias" -Stub "SampleStub"
            { New-PowerStubDirectAlias -AliasName "forcealias" -Stub "SampleStub" -Force } | Should -Not -Throw
        }

        It "Should return info object with AliasName, Stub, and StubPath" {
            $result = New-PowerStubDirectAlias -AliasName "myalias" -Stub "SampleStub"

            $result | Should -Not -BeNullOrEmpty
            $result.AliasName | Should -Be "myalias"
            $result.Stub | Should -Be "SampleStub"
            $result.StubPath | Should -Be $script:SampleStubRoot
            $result.Usage | Should -Not -BeNullOrEmpty
        }

        It "Should store alias in config for persistence" {
            New-PowerStubDirectAlias -AliasName "configalias" -Stub "SampleStub"

            $directAliases = InModuleScope PowerStub { Get-PowerStubConfigurationKey 'DirectAliases' }
            $directAliases | Should -Not -BeNullOrEmpty
            $directAliases['configalias'] | Should -Be 'SampleStub'
        }
    }

    Context "Alias Functionality" {
        BeforeEach {
            New-PowerStub -Name "SampleStub" -Path $script:SampleStubRoot -Force
            Disable-PowerStubAlphaCommands
            Disable-PowerStubBetaCommands
            New-PowerStubDirectAlias -AliasName "ts" -Stub "SampleStub" -Force
        }

        It "Should list commands when run without arguments" {
            $output = ts
            $output | Should -Not -BeNullOrEmpty
        }

        It "Should execute commands with parameters" {
            $output = ts deploy -Environment "test"
            $output | Should -Contain "deploy.ps1 (production) executed"
        }
    }

    Context "Tab Completion" {
        BeforeEach {
            New-PowerStub -Name "SampleStub" -Path $script:SampleStubRoot -Force
            Disable-PowerStubAlphaCommands
            Disable-PowerStubBetaCommands
            New-PowerStubDirectAlias -AliasName "ts" -Stub "SampleStub" -Force
        }

        It "Should complete command names using ArgumentCompleter" {
            # Test the completer directly by simulating what happens during tab completion
            # The ArgumentCompleter returns command names for the stub
            $commands = InModuleScope PowerStub {
                $commands = @(Find-PowerStubCommands "SampleStub")
                @($commands | ForEach-Object {
                    $name = $_.BaseName
                    if ($name -match '^(alpha|beta)\.(.+)$') {
                        $Matches[2]
                    } else {
                        $name
                    }
                } | Select-Object -Unique)
            }
            $commands | Should -Contain 'deploy'
        }

        It "Should complete dynamic parameters for commands" {
            $input = 'ts deploy -'
            $completions = [System.Management.Automation.CommandCompletion]::CompleteInput($input, $input.Length, $null)

            $completionTexts = @($completions.CompletionMatches | Select-Object -ExpandProperty CompletionText)
            $completionTexts | Should -Contain '-Environment'
        }
    }
}

Describe "Remove-PowerStubDirectAlias" {
    BeforeAll {
        Import-PowerStubConfiguration -Reset
        New-PowerStub -Name "SampleStub" -Path $script:SampleStubRoot -Force
    }

    BeforeEach {
        # Clean up any test aliases
        @('removeme', 'keepme') | ForEach-Object {
            if (Get-Command $_ -ErrorAction SilentlyContinue) {
                Remove-Item "function:global:$_" -ErrorAction SilentlyContinue
            }
        }
        # Clear direct aliases from config
        InModuleScope PowerStub { Set-PowerStubConfigurationKey 'DirectAliases' @{} }
    }

    AfterAll {
        # Clean up test aliases
        @('removeme', 'keepme') | ForEach-Object {
            if (Get-Command $_ -ErrorAction SilentlyContinue) {
                Remove-Item "function:global:$_" -ErrorAction SilentlyContinue
            }
        }
    }

    Context "Parameter Validation" {
        It "Should require -AliasName parameter" {
            { Remove-PowerStubDirectAlias } | Should -Throw
        }

        It "Should throw when alias doesn't exist in config" {
            { Remove-PowerStubDirectAlias -AliasName "nonexistent" } | Should -Throw "*not found*"
        }
    }

    Context "Alias Removal" {
        It "Should remove the global function" {
            New-PowerStubDirectAlias -AliasName "removeme" -Stub "SampleStub"
            Get-Command "removeme" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty

            Remove-PowerStubDirectAlias -AliasName "removeme"

            Get-Command "removeme" -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It "Should remove alias from config" {
            New-PowerStubDirectAlias -AliasName "removeme" -Stub "SampleStub"

            $directAliases = InModuleScope PowerStub { Get-PowerStubConfigurationKey 'DirectAliases' }
            $directAliases['removeme'] | Should -Be 'SampleStub'

            Remove-PowerStubDirectAlias -AliasName "removeme"

            $directAliases = InModuleScope PowerStub { Get-PowerStubConfigurationKey 'DirectAliases' }
            $directAliases.ContainsKey('removeme') | Should -Be $false
        }

        It "Should not affect other aliases" {
            New-PowerStubDirectAlias -AliasName "removeme" -Stub "SampleStub"
            New-PowerStubDirectAlias -AliasName "keepme" -Stub "SampleStub"

            Remove-PowerStubDirectAlias -AliasName "removeme"

            Get-Command "keepme" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            $directAliases = InModuleScope PowerStub { Get-PowerStubConfigurationKey 'DirectAliases' }
            $directAliases['keepme'] | Should -Be 'SampleStub'
        }
    }
}

Describe "Edge Cases and Error Handling" {
    BeforeAll {
        Import-PowerStubConfiguration -Reset
    }

    Context "Invalid Input" {
        It "Should handle missing Commands folder gracefully" {
            $testPath = Join-Path $env:TEMP "PowerStubTest_$(Get-Random)"
            New-Item $testPath -ItemType Directory -Force | Out-Null

            try {
                New-PowerStub -Name "EmptyStub" -Path $testPath -Force
                # Remove the Commands folder
                Remove-Item (Join-Path $testPath 'Commands') -Recurse -Force

                $cmd = Get-PowerStubCommand -Stub "EmptyStub" -Command "test" -WarningVariable warn -WarningAction SilentlyContinue
                $cmd | Should -BeNullOrEmpty
            }
            finally {
                if (Test-Path $testPath) {
                    Remove-Item $testPath -Recurse -Force
                }
            }
        }
    }

    Context "Special Characters" {
        It "Should handle stub names with valid characters" {
            $testPath = Join-Path $env:TEMP "PowerStubTest_$(Get-Random)"

            try {
                New-PowerStub -Name "Test-Stub_123" -Path $testPath

                $stubs = Get-PowerStubs
                $stubs.Keys | Should -Contain "Test-Stub_123"
            }
            finally {
                if (Test-Path $testPath) {
                    Remove-Item $testPath -Recurse -Force
                }
            }
        }
    }
}
