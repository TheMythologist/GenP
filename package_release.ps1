param([string]$Version = 'v4.2.2')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($Version -cne 'v4.2.2') { throw 'Only the maintained v4.2.2 release is supported.' }
$releaseDir = Join-Path $PSScriptRoot "$Version\Release"
$manifestPath = Join-Path $releaseDir 'build-manifest.json'
& (Join-Path $PSScriptRoot 'verify_build.ps1') -Manifest $manifestPath
$record = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$exePath = Join-Path $PSScriptRoot $record.output.path
$configPath = Join-Path $PSScriptRoot "$Version\GenP\config.ini"
$exeName = "GenP-$Version.exe"
if ((Split-Path $exePath -Leaf) -cne $exeName) { throw 'Unexpected executable in build manifest.' }
$zipPath = Join-Path $releaseDir "GenP-$Version.zip"
if (Test-Path -LiteralPath $zipPath) { throw "Package already exists: $zipPath" }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
try {
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $exePath, $exeName, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $configPath, 'config.ini', [IO.Compression.CompressionLevel]::Optimal) | Out-Null
} finally { $zip.Dispose() }
$expected = @{}
$expected[$exeName] = $record.output.sha256
$expected['config.ini'] = (Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToLowerInvariant()
$zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    if ($zip.Entries.Count -ne 2) { throw 'Runtime ZIP must contain exactly two files.' }
    $seen = @{}
    foreach ($entry in $zip.Entries) {
        if (-not $expected.ContainsKey($entry.FullName) -or $seen.ContainsKey($entry.FullName)) { throw "Unexpected ZIP entry: $($entry.FullName)" }
        $seen[$entry.FullName] = $true
        $stream = $entry.Open()
        $algorithm = [Security.Cryptography.SHA256]::Create()
        try { $entryHash = -join ($algorithm.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) } finally { $stream.Dispose(); $algorithm.Dispose() }
        if ($entryHash -cne $expected[$entry.FullName]) { throw "ZIP hash mismatch: $($entry.FullName)" }
    }
} finally { $zip.Dispose() }
$sums = @(
    foreach ($path in @($zipPath, $exePath, $configPath, $manifestPath)) {
        '{0}  {1}' -f (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant(), (Split-Path $path -Leaf)
    }
)
[IO.File]::WriteAllLines((Join-Path $releaseDir 'SHA256SUMS.txt'), [string[]]$sums, [Text.UTF8Encoding]::new($false))
Write-Host "Verified runtime package: $zipPath"
Write-Host $sums[0]
