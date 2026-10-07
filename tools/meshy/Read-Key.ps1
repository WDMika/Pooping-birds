$ErrorActionPreference = 'Stop'
# Internal credential helper: stdout is captured privately by Start-Meshy.mjs.
# Do not run this helper directly in a terminal.
$credentialPath = Join-Path $env:USERPROFILE '.codex\secrets\meshy-api-key.dpapi'
if (-not (Test-Path -LiteralPath $credentialPath)) {
    throw 'Meshy credential is missing from the current Windows user profile.'
}
$secureKey = ConvertTo-SecureString -String ([IO.File]::ReadAllText($credentialPath).Trim())
$secretPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
try {
    [Console]::Out.Write([Runtime.InteropServices.Marshal]::PtrToStringBSTR($secretPointer))
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($secretPointer)
}
