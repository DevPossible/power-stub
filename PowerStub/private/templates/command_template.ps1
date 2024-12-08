
function new-powerstubrootfolder {
		param(
				[string]$rootFolderName
		)
		$rootFolder = Join-Path $PSScriptRoot $rootFolderName
		if (-not (Test-Path $rootFolder)) {
				New-Item -ItemType Directory -Path $rootFolder
		}
}


