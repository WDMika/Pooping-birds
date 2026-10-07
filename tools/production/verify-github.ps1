param([string]$Destination)
$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if (-not $Destination) {
    $Destination = Join-Path (Split-Path $taskRoot -Parent) ('production-backups/github-restore-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
}
$taskDestination = [IO.Path]::GetFullPath($Destination)
if ($taskDestination.StartsWith($taskRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or $taskDestination -eq $taskRoot) { throw 'Clone destination must be outside the source checkout' }
if (Test-Path -LiteralPath $taskDestination) { throw 'Clone destination must not exist' }
Push-Location $taskRoot
$taskPreviousSmudge = $env:GIT_LFS_SKIP_SMUDGE
$taskPreviousInteractive = $env:GCM_INTERACTIVE
try {
    if (git status --porcelain) { throw 'Commit source changes before verification' }
    $taskExpected = (git rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read local commit' }
    $taskRemote = (git remote get-url origin).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Missing origin' }
    $taskRemoteHead = git ls-remote origin refs/heads/main
    if ($LASTEXITCODE -ne 0 -or -not $taskRemoteHead -or ($taskRemoteHead -split '\s+')[0] -ne $taskExpected) { throw 'Remote main does not match local HEAD' }
    $env:GIT_LFS_SKIP_SMUDGE = '1'
    $env:GCM_INTERACTIVE = 'Never'
    git clone --branch main --single-branch $taskRemote $taskDestination
    if ($LASTEXITCODE -ne 0) { throw 'Remote clone failed' }
    git -C $taskDestination lfs pull
    if ($LASTEXITCODE -ne 0) { throw 'Remote LFS download failed' }
    git -C $taskDestination lfs fsck
    if ($LASTEXITCODE -ne 0) { throw 'Downloaded LFS integrity check failed' }
    $taskActual = (git -C $taskDestination rev-parse HEAD).Trim()
    if ($taskActual -ne $taskExpected) { throw 'Remote clone commit mismatch' }
    $taskFiles = @(git ls-files)
    foreach ($taskRelative in $taskFiles) {
        $taskSourceFile = Join-Path $taskRoot $taskRelative
        $taskRestoredFile = Join-Path $taskDestination $taskRelative
        if (-not (Test-Path -LiteralPath $taskRestoredFile)) { throw "Missing remote file: $taskRelative" }
        if ((Get-FileHash -LiteralPath $taskSourceFile -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $taskRestoredFile -Algorithm SHA256).Hash) { throw "Remote file hash mismatch: $taskRelative" }
    }
    $taskLfsFiles = @(git lfs ls-files --name-only)
    Push-Location $taskDestination
    try {
        node tools/production/check.mjs
        if ($LASTEXITCODE -ne 0) { throw 'Remote restored workflow check failed' }
    } finally { Pop-Location }
    [pscustomobject]@{
        schema = 1
        checkedAt = (Get-Date).ToUniversalTime().ToString('o')
        repository = $taskRemote
        commit = $taskExpected
        restoredDirectory = $taskDestination
        trackedFilesVerified = $taskFiles.Count
        lfsFilesVerified = $taskLfsFiles.Count
        method = 'Fresh remote clone, explicit LFS download/fsck, SHA256 comparison of every tracked materialized file, development workflow check'
        passed = $true
        limitations = @('Does not verify a full Studio scene, Roblox asset ownership, live gameplay or player data recovery')
    } | ConvertTo-Json -Depth 4
} finally {
    $env:GIT_LFS_SKIP_SMUDGE = $taskPreviousSmudge
    $env:GCM_INTERACTIVE = $taskPreviousInteractive
    Pop-Location
}
