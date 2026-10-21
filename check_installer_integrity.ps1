[CmdletBinding()]
param(
    [string]$ComponentRoot = "${env:CommonProgramFiles(x86)}\Adobe\Adobe Desktop Common"
)

$ErrorActionPreference = 'Stop'
$relativePaths = @(
    'ADS\Adobe Desktop Service.exe',
    'AppsPanel\AppsPanelBL.dll',
    'HDBox\HDPIM.dll',
    'ElevationManager\Adobe Installer.exe'
)

$results = foreach ($relativePath in $relativePaths) {
    $componentPath = Join-Path $ComponentRoot $relativePath
    $status = 'Missing'
    $signer = $null
    if (Test-Path -LiteralPath $componentPath -PathType Leaf) {
        try {
            $signature = Get-AuthenticodeSignature -LiteralPath $componentPath
            $status = [string]$signature.Status
            if ($signature.SignerCertificate) {
                $signer = $signature.SignerCertificate.Subject
            }
        } catch {
            $status = 'CheckFailed'
        }
    }
    [PSCustomObject]@{
        Component = $relativePath
        Status = $status
        AdobeSignatureValid = ($status -eq 'Valid' -and $signer -match '(?:^|,\s*)O=Adobe (?:Inc\.|Systems Incorporated)(?:,|$)')
    }
}

$results | Format-Table -AutoSize
if (@($results | Where-Object { -not $_.AdobeSignatureValid }).Count -gt 0) {
    Write-Warning 'Installer integrity check failed. Modified components can cause installer IPC validation to fail and leave installation waiting. Restore original signed components using Adobe repair before retrying.'
    exit 1
}
Write-Output 'Selected installer components have valid Adobe signatures.'
exit 0
