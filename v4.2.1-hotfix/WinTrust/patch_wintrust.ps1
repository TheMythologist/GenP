<#
Patch wintrust.dll
greets Team V.R
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$winTrustSource = Join-Path $scriptDir "wintrust.dll"
$winTrustPatched = Join-Path $scriptDir "wintrust.dll.patched"

function Test-ExecutionPolicy {
    $policy = Get-ExecutionPolicy -Scope CurrentUser
    if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned') {
        Write-Warning "Current execution policy ($policy) may prevent running this script."
        Write-Host "To allow running scripts, you can set the execution policy to RemoteSigned or Bypass."
        Write-Host "Run this command in an elevated PowerShell prompt:"
        Write-Host "    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force"
        Write-Host "Alternatively, run this script with: powershell.exe -ExecutionPolicy Bypass -File .\patch.ps1"
        exit 1
    }
}

function Test-FileAccess {
    param (
        [string]$Path,
        [string]$Description
    )
    if (-not (Test-Path $Path)) {
        Write-Error "$Description not found at $Path"
        exit 1
    }
    try {
        [System.IO.File]::OpenWrite($Path).Close()
    }
    catch {
        Write-Error "Cannot write to $Description at $Path. Ensure you have permissions or run as Administrator."
        exit 1
    }
}

Test-ExecutionPolicy

Test-FileAccess -Path $winTrustSource -Description "wintrust.dll"

try {
    Copy-Item -Path $winTrustSource -Destination $winTrustPatched -Force
}
catch {
    Write-Error "Failed to copy wintrust.dll to wintrust.dll.patched: $_"
    exit 1
}

try {
    $bytes = [System.IO.File]::ReadAllBytes($winTrustPatched)
    $bytes[0x1C86] = 0x33
    $bytes[0x1C87] = 0xC0
    [System.IO.File]::WriteAllBytes($winTrustPatched, $bytes)
}
catch {
    Write-Error "Failed to patch wintrust.dll.patched: $_"
    exit 1
}