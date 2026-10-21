param([string]$Manifest = (Join-Path $PSScriptRoot 'v4.2.2\Release\build-manifest.json'))
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$buildRecord = Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json
$projectPrefix = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\') + '\'
foreach ($entry in @($buildRecord.inputs) + @($buildRecord.output)) {
    $entryPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot $entry.path))
    if (-not $entryPath.StartsWith($projectPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw "Manifest path leaves the project: $($entry.path)" }
    if (-not (Test-Path -LiteralPath $entryPath -PathType Leaf)) { throw "Missing file: $($entry.path)" }
    $actualHash = (Get-FileHash -LiteralPath $entryPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $entry.sha256 -or (Get-Item -LiteralPath $entryPath).Length -ne $entry.bytes) { throw "Build verification failed: $($entry.path)" }
}
$outputPath = Join-Path $PSScriptRoot $buildRecord.output.path
$outputBytes = [IO.File]::ReadAllBytes($outputPath)
if ($outputBytes.Length -le 80) { throw 'Executable self-hash trailer is missing.' }
$outputBodyLength = $outputBytes.Length - 80
$outputMagic = [Text.Encoding]::ASCII.GetString($outputBytes, $outputBodyLength, 16)
$recordedBodyHash = [Text.Encoding]::ASCII.GetString($outputBytes, $outputBodyLength + 16, 64)
$hashAlgorithm = [Security.Cryptography.SHA256]::Create()
try { $actualBodyHash = -join ($hashAlgorithm.ComputeHash($outputBytes, 0, $outputBodyLength) | ForEach-Object { $_.ToString('x2') }) } finally { $hashAlgorithm.Dispose() }
if ($outputMagic -cne 'GENP_SELFHASH_01' -or $recordedBodyHash -cne $actualBodyHash) { throw 'Executable self-hash verification failed.' }
Write-Host "Verified $(@($buildRecord.inputs).Count) build inputs and $($buildRecord.output.path)."
Write-Host "Executable SHA256: $($buildRecord.output.sha256)"
