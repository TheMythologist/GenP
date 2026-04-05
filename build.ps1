<#
Build GenP
Requires administrative privileges
Run with: .\build.ps1 or via run_build.bat
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Default paths -- customize as needed
$installBaseDir = Join-Path $env:SystemDrive "GenP-BuildEnv"
$autoItInstallDir = Join-Path $installBaseDir "AutoIt"
$autoItCoreExe = Join-Path $autoItInstallDir "install\AutoIt3_x64.exe"
$sciteInstallDir = Join-Path $autoItInstallDir "install\SciTE"
$wrapperScript = Join-Path $sciteInstallDir "AutoIt3Wrapper\AutoIt3Wrapper.au3"
$scriptDir = $PSScriptRoot
$genpDir = Join-Path $scriptDir "GenP"
$logsDir = Join-Path $scriptDir "Logs"
$releaseDir = Join-Path $scriptDir "Release"
$upxDir = Join-Path $scriptDir "UPX"
$winTrustDir = Join-Path $scriptDir "WinTrust"
$autoItZipPath = Join-Path $scriptDir "autoit-v3.zip"
$sciTEZipPath = Join-Path $scriptDir "SciTE4AutoIt3_Portable.zip"
$logPath = Join-Path $logsDir "build.log"
$upxExe = Join-Path $genpDir "upx.exe"
$winTrustDll = Join-Path $genpDir "wintrust.dll"

if (-not (Test-Path $logsDir)) {
    New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path $releaseDir)) {
    New-Item -Path $releaseDir -ItemType Directory -Force | Out-Null
}

# Download URLs -- update as needed
$autoItUrl = "https://www.autoitscript.com/files/autoit3/autoit-v3.zip"
$sciTEUrl = "https://www.autoitscript.com/autoit3/scite/download/SciTE4AutoIt3_Portable.zip"

$winTrustStockHash = "1B3BF770D4F59CA883391321A21923AE"
$winTrustPatchedHash = "B7A38368A52FF07D875E6465BD7EE26A"

Start-Transcript -Path $logPath -Append -NoClobber | Out-Null

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-ExecutionPolicy {
    $policy = Get-ExecutionPolicy -Scope CurrentUser
    if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned') {
        Write-Warning "Current execution policy ($policy) may prevent running this script."
        Write-Host "Run this command in an elevated PowerShell prompt:"
        Write-Host "    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force"
        Write-Host "Alternatively, use run_build.bat to run this script."
        Stop-Transcript | Out-Null
        exit 1
    }
}

function Get-MD5Hash {
    param ([string]$filePath)
    if (-not (Test-Path $filePath)) { return $null }
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($filePath))).Replace("-", "").ToUpper()
    return $hash
}

function Get-UserConfirmation {
    param ([string]$Prompt)
    Write-Host $Prompt
    $response = Read-Host "Enter 'y' to proceed, 'n' to cancel"
    return $response -eq 'y' -or $response -eq 'Y'
}

function Download-File {
    param (
        [string]$Url,
        [string]$Destination
    )
    $success = $false
    $errorMessage = ""

    try {
        $curl = "curl.exe"
        if (Get-Command $curl -ErrorAction SilentlyContinue) {
            & $curl -L -o "$Destination" "$Url" --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" --silent --show-error --connect-timeout 30
            if ($LASTEXITCODE -eq 0 -and (Test-Path $Destination)) {
                $success = $true
            }
            else {
                $errorMessage = "curl failed with exit code $LASTEXITCODE"
            }
        }
    }
    catch {
        $errorMessage = "curl error: $_"
    }

    if (-not $success) {
        try {
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
            $wc.DownloadFile($Url, $Destination)
            if (Test-Path $Destination) {
                $success = $true
            }
            else {
                $errorMessage = "WebClient completed but file not found"
            }
        }
        catch {
            $errorMessage = "WebClient error: $_"
        }
    }

    if (-not $success) {
        Write-Error "Failed to download $Url to $Destination - $errorMessage"
        Stop-Transcript | Out-Null
        exit 1
    }
}

Test-ExecutionPolicy

if (-not (Test-Admin)) {
    Write-Error "This script must be run as an Administrator. Right-click run_build.bat and select 'Run as administrator'."
    Stop-Transcript | Out-Null
    exit 1
}

if (-not (Test-Path $genpDir)) {
    Write-Error "GenP directory not found at $genpDir."
    Stop-Transcript | Out-Null
    exit 1
}
if (-not (Test-Path $upxDir)) {
    Write-Error "UPX directory not found at $upxDir."
    Stop-Transcript | Out-Null
    exit 1
}
if (-not (Test-Path $winTrustDir)) {
    Write-Error "WinTrust directory not found at $winTrustDir."
    Stop-Transcript | Out-Null
    exit 1
}

$hasAutoIt = Test-Path $autoItCoreExe
$hasSciTE = Test-Path $wrapperScript
$hasUpx = Test-Path $upxExe
$hasWinTrust = Test-Path $winTrustDll
$winTrustStatus = if ($hasWinTrust) {
    $hash = Get-MD5Hash $winTrustDll
    if ($hash -eq $winTrustPatchedHash) { "patched" }
    elseif ($hash -eq $winTrustStockHash) { "stock" }
    else { "unknown" }
} else { "missing" }

Write-Host "Starting build process..." -ForegroundColor Magenta

if ($hasUpx) {
    Write-Host " - upx.exe found in $genpDir\, skipped preparing UPX" -ForegroundColor Green
}
if ($hasWinTrust -and $winTrustStatus -eq "patched") {
    Write-Host " - wintrust.dll found in $genpDir\, skipped patching WinTrust" -ForegroundColor Green
}
elseif ($hasWinTrust -and $winTrustStatus -eq "unknown") {
    Write-Warning "wintrust.dll in $genpDir\ has unknown MD5 hash." -ForegroundColor Yellow
    if (-not (Get-UserConfirmation -Prompt "Proceed with current wintrust.dll? (y/n)")) {
        Write-Error "User chose not to proceed with unknown wintrust.dll."
        Stop-Transcript | Out-Null
        exit 1
    }
}
if ($hasAutoIt) {
    Write-Host " - AutoIt found in $autoItInstallDir\, skipped downloading AutoIt" -ForegroundColor Green
}
if ($hasSciTE) {
    Write-Host " - SciTE found in $sciteInstallDir\, skipped downloading SciTE" -ForegroundColor Green
}

$downloadsNeeded = @()
if (!$hasAutoIt) { $downloadsNeeded += "AutoIt Portable (~17MB)" }
if (!$hasSciTE) { $downloadsNeeded += "SciTE Portable (~7MB)" }

if ($downloadsNeeded.Count -gt 0) {
    Write-Host "The following components are missing and need to be downloaded:" -ForegroundColor Yellow
    $downloadsNeeded | ForEach-Object { Write-Host " - $_" }
    if (-not (Get-UserConfirmation -Prompt "Proceed with downloading these components? (y/n)")) {
        Write-Host "Operation cancelled by user."
        Stop-Transcript | Out-Null
        exit 0
    }
}

if (-not (Test-Path $installBaseDir)) {
    Write-Host ""
    Write-Host "Creating installation directory at $installBaseDir..." -ForegroundColor Cyan
    New-Item -Path $installBaseDir -ItemType Directory -Force | Out-Null
}

if (!$hasUpx) {
    Write-Host ""
    Write-Host "Preparing UPX..." -ForegroundColor Cyan
    try {
        $upxExtractedDir = Get-ChildItem -Path $upxDir -Directory | Where-Object { $_.Name -match '^upx-.*-win64$' } | Select-Object -First 1
        if (-not $upxExtractedDir) {
            $upxZip = Get-ChildItem -Path $upxDir -File | Where-Object { $_.Name -match '^upx-.*-win64\.zip$' } | Select-Object -First 1
            if (-not $upxZip) {
                Write-Error "No UPX extracted directory or zip file found in $upxDir."
                Stop-Transcript | Out-Null
                exit 1
            }
            Write-Host " - Extracting zip: $($upxZip.Name)"
            
            $tarExe = "tar.exe"
            $extracted = $false
            if (Get-Command $tarExe -ErrorAction SilentlyContinue) {
                $tarOutLog = Join-Path $logsDir "tar_out.log"
                $tarErrLog = Join-Path $logsDir "tar_err.log"
                $process = Start-Process -FilePath $tarExe -ArgumentList "-xf `"$($upxZip.FullName)`" -C `"$upxDir`"" -Wait -PassThru -RedirectStandardOutput $tarOutLog -RedirectStandardError $tarErrLog
                if ($process.ExitCode -eq 0) {
                    $extracted = $true
                }
                else {
                    Write-Warning "tar.exe failed to extract $($upxZip.Name). Check $tarErrLog. Falling back to Expand-Archive."
                }
            }
            
            if (-not $extracted) {
                $unzipErrLog = Join-Path $logsDir "unzip_err.log"
                Expand-Archive -Path $upxZip.FullName -DestinationPath $upxDir -Force -ErrorAction Stop 2> $unzipErrLog
            }
            
            $upxExtractedDir = Get-ChildItem -Path $upxDir -Directory | Where-Object { $_.Name -match '^upx-.*-win64$' } | Select-Object -First 1
            if (-not $upxExtractedDir) {
                Write-Error "UPX extracted directory not found in $upxDir after extraction."
                Stop-Transcript | Out-Null
                exit 1
            }
        }
        $upxExtractedDir = $upxExtractedDir.FullName
        Write-Host " - Found UPX directory: $upxExtractedDir"
        
        $upxExe = Join-Path $upxExtractedDir "upx.exe"
        if (-not (Test-Path $upxExe)) {
            Write-Error "UPX executable not found at $upxExe."
            Stop-Transcript | Out-Null
            exit 1
        }
        
        Copy-Item -Path $upxExe -Destination $genpDir -Force
        Write-Host " - UPX copied to $genpDir" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to prepare UPX: $_"
        Stop-Transcript | Out-Null
        exit 1
    }
}

if ($hasWinTrust -and $winTrustStatus -eq "patched") {
} elseif (!$hasWinTrust -or $winTrustStatus -eq "stock" -or $winTrustStatus -eq "unknown") {
    Write-Host ""
    Write-Host "Patching wintrust.dll..." -ForegroundColor Cyan
    try {
        $patchScript = Join-Path $winTrustDir "patch_wintrust.ps1"
        $winTrustSource = Join-Path $winTrustDir "wintrust.dll"
        if (-not (Test-Path $patchScript)) {
            Write-Error "patch_wintrust.ps1 not found in $winTrustDir"
            Stop-Transcript | Out-Null
            exit 1
        }
        if (-not (Test-Path $winTrustSource)) {
            Write-Error "wintrust.dll not found in $winTrustDir"
            Stop-Transcript | Out-Null
            exit 1
        }
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$patchScript`"" -WorkingDirectory $winTrustDir -Wait -NoNewWindow
        $winTrustPatched = Join-Path $winTrustDir "wintrust.dll.patched"
        if (-not (Test-Path $winTrustPatched)) {
            Write-Error "wintrust.dll.patched not found in $winTrustDir after patching"
            Stop-Transcript | Out-Null
            exit 1
        }
        Move-Item -Path $winTrustPatched -Destination $winTrustDll -Force
        Write-Host " - Patched wintrust.dll and moved to $genpDir" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to patch or move wintrust.dll: $_"
        Stop-Transcript | Out-Null
        exit 1
    }
}

if (!$hasAutoIt) {
    Write-Host ""
    Write-Host "Downloading AutoIt Portable..." -ForegroundColor Cyan
    try {
        Download-File -Url $autoItUrl -Destination $autoItZipPath
        Write-Host " - Extracting AutoIt Portable to $autoItInstallDir"
        
        New-Item -Path $autoItInstallDir -ItemType Directory -Force | Out-Null
        Remove-Item -Path "$autoItInstallDir\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        $tarExe = "tar.exe"
        $extracted = $false
        if (Get-Command $tarExe -ErrorAction SilentlyContinue) {
            $tarOutLog = Join-Path $logsDir "tar_out.log"
            $tarErrLog = Join-Path $logsDir "tar_err.log"
            $process = Start-Process -FilePath $tarExe -ArgumentList "-xf `"$autoItZipPath`" -C `"$autoItInstallDir`"" -Wait -PassThru -RedirectStandardOutput $tarOutLog -RedirectStandardError $tarErrLog
            if ($process.ExitCode -eq 0) {
                $extracted = $true
            }
            else {
                Write-Warning "tar.exe failed to extract $(Split-Path -Leaf $autoItZipPath). Check $tarErrLog. Falling back to Expand-Archive."
            }
        }
        
        if (-not $extracted) {
            $unzipErrLog = Join-Path $logsDir "unzip_err.log"
            Expand-Archive -Path $autoItZipPath -DestinationPath $autoItInstallDir -Force -ErrorAction Stop 2> $unzipErrLog
        }
        
        Remove-Item $autoItZipPath -Force -ErrorAction SilentlyContinue
        Write-Host " - AutoIt extracted to $autoItInstallDir" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download or extract AutoIt Portable: $_"
        Stop-Transcript | Out-Null
        exit 1
    }
}

if (!$hasSciTE) {
    Write-Host ""
    Write-Host "Downloading SciTE Portable..." -ForegroundColor Cyan
    try {
        Download-File -Url $sciTEUrl -Destination $sciTEZipPath
        $sciTEDestDir = Join-Path $autoItInstallDir "install\SciTE"
        Write-Host " - Extracting SciTE Portable to $sciTEDestDir"
        
        New-Item -Path $sciTEDestDir -ItemType Directory -Force | Out-Null
        Remove-Item -Path "$sciTEDestDir\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        $tarExe = "tar.exe"
        $extracted = $false
        if (Get-Command $tarExe -ErrorAction SilentlyContinue) {
            $tarOutLog = Join-Path $logsDir "tar_out.log"
            $tarErrLog = Join-Path $logsDir "tar_err.log"
            $process = Start-Process -FilePath $tarExe -ArgumentList "-xf `"$sciTEZipPath`" -C `"$sciTEDestDir`"" -Wait -PassThru -RedirectStandardOutput $tarOutLog -RedirectStandardError $tarErrLog
            if ($process.ExitCode -eq 0) {
                $extracted = $true
            }
            else {
                Write-Warning "tar.exe failed to extract $(Split-Path -Leaf $sciTEZipPath). Check $tarErrLog. Falling back to Expand-Archive."
            }
        }
        
        if (-not $extracted) {
            $unzipErrLog = Join-Path $logsDir "unzip_err.log"
            Expand-Archive -Path $sciTEZipPath -DestinationPath $sciTEDestDir -Force -ErrorAction Stop 2> $unzipErrLog
        }
        
        Remove-Item $sciTEZipPath -Force -ErrorAction SilentlyContinue
        Write-Host " - SciTE extracted to $sciTEDestDir" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download or extract SciTE Portable: $_"
        Stop-Transcript | Out-Null
        exit 1
    }
}

Write-Host ""
Write-Host "Building GenP..." -ForegroundColor Cyan
try {
    $au3Files = @(Get-ChildItem -Path $genpDir -Filter "*.au3" -File -ErrorAction Stop)
    if ($au3Files.Count -eq 0) {
        Write-Error "No .au3 files found in $genpDir."
        Stop-Transcript | Out-Null
        exit 1
    }
    if ($au3Files.Count -gt 1) {
        $strippedFiles = @($au3Files | Where-Object { $_.Name -like "*_stripped.au3" })
        if ($strippedFiles) {
            Write-Host " - Found stripped .au3 file(s): $($strippedFiles.Name -join ', '). Deleting to proceed with build." -ForegroundColor Yellow
            $strippedFiles | ForEach-Object { Remove-Item $_.FullName -Force }
            $au3Files = @(Get-ChildItem -Path $genpDir -Filter "*.au3" -File -ErrorAction Stop)
        }
    }
    if ($au3Files.Count -ne 1) {
        Write-Error "Expected one .au3 file in $genpDir after cleanup, found $($au3Files.Count): $($au3Files.Name -join ', ')"
        Stop-Transcript | Out-Null
        exit 1
    }
    $au3File = $au3Files[0].FullName
    Write-Host " - Selected .au3 file: $au3File"
    if (-not (Test-Path $autoItCoreExe)) {
        Write-Error "AutoIt3_x64.exe not found in $autoItInstallDir\install."
        Stop-Transcript | Out-Null
        exit 1
    }
    if (-not (Test-Path $wrapperScript)) {
        Write-Error "AutoIt3Wrapper.au3 not found in $autoItInstallDir\install\SciTE\AutoIt3Wrapper."
        Stop-Transcript | Out-Null
        exit 1
    }
    $au3FileName = Split-Path $au3File -Leaf
    Write-Host " - Building $au3FileName"
    $autoItOutLog = Join-Path $logsDir "AutoIt_out.log"
    $autoItErrLog = Join-Path $logsDir "AutoIt_err.log"
    Remove-Item -Path (Join-Path $genpDir "GenP*.exe") -Force -ErrorAction SilentlyContinue
    $autoItArgs = "`"$wrapperScript`" /NoStatus /in `"$au3File`""
    Start-Process -FilePath $autoItCoreExe -ArgumentList $autoItArgs -WorkingDirectory $genpDir -RedirectStandardOutput $autoItOutLog -RedirectStandardError $autoItErrLog -Wait -ErrorAction Stop
    $exeFiles = @(Get-ChildItem -Path $genpDir -Filter "GenP*.exe" -File -ErrorAction Stop | Sort-Object LastWriteTime -Descending)
    if ($exeFiles.Count -eq 0) {
        Write-Error "AutoIt3Wrapper failed to produce a GenP*.exe in $genpDir. Check $autoItErrLog."
        Write-Host " - Searching for misplaced executables" -ForegroundColor Yellow
        $misplacedExes = @(Get-ChildItem -Path $genpDir,$scriptDir,$installBaseDir,"C:\Windows\System32" -Filter "*.exe" -File -Recurse -ErrorAction SilentlyContinue)
        if ($misplacedExes.Count -gt 0) {
            Write-Host " - Found $($misplacedExes.Count) executable(s) in other directories: $($misplacedExes.FullName -join ', ')" -ForegroundColor Yellow
        }
        Stop-Transcript | Out-Null
        exit 1
    }
    if ($exeFiles.Count -gt 1) {
        $exeNames = $exeFiles.Name -join ', '
        Write-Host " - Warning: Found multiple GenP*.exe files in $genpDir - $exeNames. Using most recent: $($exeFiles[0].Name)" -ForegroundColor Yellow
    }
    $genpExe = $exeFiles[0].FullName
    $releaseExe = Join-Path $releaseDir $exeFiles[0].Name
    Move-Item -Path $genpExe -Destination $releaseExe -Force -ErrorAction Stop
    if (-not (Test-Path $releaseExe)) {
        Write-Error "Failed to move $genpExe to $releaseExe."
        Stop-Transcript | Out-Null
        exit 1
    }
    Write-Host " - GenP executable built at $releaseExe" -ForegroundColor Green
    Remove-Item -Path (Join-Path $genpDir "GenP*_stripped.au3") -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Host "Failed to build AutoIt script: $_" -ForegroundColor Red
    Stop-Transcript | Out-Null
    exit 1
}

Write-Host ""
Write-Host "Build process completed successfully!" -ForegroundColor Magenta
Stop-Transcript | Out-Null
