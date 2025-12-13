<#
.SYNOPSIS
  Gets the path from a stub configuration.

.DESCRIPTION
  Extracts the path from a stub configuration, which can be either:
  - A simple string (legacy format)
  - A hashtable with a 'Path' key (new format with git support)

.PARAMETER StubConfig
  The stub configuration to extract the path from.

.OUTPUTS
  The path string.

.EXAMPLE
  Get-PowerStubPath -StubConfig "C:\MyStub"
  Get-PowerStubPath -StubConfig @{ Path = "C:\MyStub"; GitRepoUrl = "https://..." }
#>

function Get-PowerStubPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $StubConfig
    )

    if ($null -eq $StubConfig) {
        return $null
    }

    if ($StubConfig -is [hashtable]) {
        return $StubConfig.Path
    }

    if ($StubConfig -is [PSCustomObject]) {
        return $StubConfig.Path
    }

    # Assume it's a string
    return [string]$StubConfig
}
