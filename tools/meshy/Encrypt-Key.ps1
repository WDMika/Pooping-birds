$ErrorActionPreference = 'Stop'
# The caller supplies the secret on stdin, never as a command-line argument.
$secretText = [Console]::In.ReadToEnd().Trim()
if (-not $secretText.StartsWith('msy_')) { throw 'Invalid Meshy key format.' }
$secureKey = ConvertTo-SecureString -String $secretText -AsPlainText -Force
$secretText = $null
[Console]::Out.Write((ConvertFrom-SecureString -SecureString $secureKey))
