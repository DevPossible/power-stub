function Sync-PowerStubConfiguration {
    [CmdletBinding()]
    param()

    $fileName = Get-PowerStubConfigurationKey 'ConfigFile'
    if (-not $fileName -or -not (Test-Path -LiteralPath $fileName)) {
        return
    }

    try {
        $currentLastWrite = (Get-Item -LiteralPath $fileName -ErrorAction Stop).LastWriteTimeUtc
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        return
    }

    $knownLastWrite = Get-PowerStubConfigurationKey 'ConfigFileLastWriteUtc'

    if ($knownLastWrite -and $currentLastWrite -le $knownLastWrite) {
        return
    }

    try {
        Import-PowerStubConfiguration -ErrorAction Stop
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        return
    }
}
