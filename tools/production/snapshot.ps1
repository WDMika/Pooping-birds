param([string]$Label='checkpoint')
$ErrorActionPreference='Stop'
$taskRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if($Label -notmatch '^[a-zA-Z0-9-]+$'){throw 'Label must contain letters, digits or hyphens'}
$taskBackupRoot=Join-Path (Split-Path $taskRoot -Parent) 'production-backups'
New-Item -ItemType Directory -Path $taskBackupRoot -Force | Out-Null
$taskStamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$taskDestination=Join-Path $taskBackupRoot "$taskStamp-$Label"
New-Item -ItemType Directory -Path $taskDestination | Out-Null
Push-Location $taskRoot
try{
 $taskChanges=git status --porcelain
 if($taskChanges){throw 'Commit source changes before taking a Git snapshot'}
 git bundle create (Join-Path $taskDestination 'project.bundle') --all
 if($LASTEXITCODE -ne 0){throw 'Git bundle failed'}
 git bundle verify (Join-Path $taskDestination 'project.bundle')
 if($LASTEXITCODE -ne 0){throw 'Git bundle verification failed'}
 Compress-Archive -LiteralPath (Join-Path $taskRoot 'assets') -DestinationPath (Join-Path $taskDestination 'asset-sources.zip')
 git rev-parse HEAD | Set-Content -LiteralPath (Join-Path $taskDestination 'commit.txt')
 'Includes Git history and materialized assets. Full Studio scene is included only if saved under assets/scenes. No player data or credentials.' | Set-Content -LiteralPath (Join-Path $taskDestination 'README.txt')
 Write-Output "Verified snapshot: $taskDestination"
}finally{Pop-Location}
