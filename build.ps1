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
$msys2InstallDir = Join-Path $installBaseDir "msys64"
$bashPath = Join-Path $msys2InstallDir "usr\bin\bash.exe"
$scriptDir = $PSScriptRoot
$genpDir = Join-Path $scriptDir "GenP"
$logsDir = Join-Path $scriptDir "Logs"
$releaseDir = Join-Path $scriptDir "Release"
$upxDir = Join-Path $scriptDir "UPX"
$winTrustDir = Join-Path $scriptDir "WinTrust"
$autoItZipPath = Join-Path $scriptDir "autoit-v3.zip"
$msys2ExePath = Join-Path $scriptDir "msys2-base-x86_64-latest.sfx.exe"
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
$msys2Url = "https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe"

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
    Write-Error "UPX source directory not found at $upxDir."
    Stop-Transcript | Out-Null
    exit 1
}
if (-not (Test-Path $winTrustDir)) {
    Write-Error "WinTrust directory not found at $winTrustDir."
    Stop-Transcript | Out-Null
    exit 1
}

$hasMsys2 = Test-Path $bashPath
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
    Write-Host " - upx.exe found at $upxExe, skipped building upx.exe"
}
if ($hasWinTrust -and $winTrustStatus -eq "patched") {
    Write-Host " - wintrust.dll found at $winTrustDll, skipped patching wintrust.dll"
}
elseif ($hasWinTrust -and $winTrustStatus -eq "unknown") {
    Write-Warning "wintrust.dll at $winTrustDll has unknown MD5 hash." -ForegroundColor Yellow
    if (-not (Get-UserConfirmation -Prompt "Proceed with current wintrust.dll? (y/n)")) {
        Write-Error "User chose not to proceed with unknown wintrust.dll."
        Stop-Transcript | Out-Null
        exit 1
    }
}
if ($hasMsys2 -and !$hasUpx) {
    Write-Host " - MSYS2 found at $msys2InstallDir, skipped downloading MSYS2"
}
if ($hasAutoIt) {
    Write-Host " - AutoIt found at $autoItInstallDir, skipped downloading AutoIt"
}
if ($hasSciTE) {
    Write-Host " - SciTE found at $sciteInstallDir, skipped downloading SciTE"
}

$downloadsNeeded = @()
if (!$hasUpx -and !$hasMsys2) { $downloadsNeeded += "MSYS2 (~50MB)" }
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

if (!$hasUpx -and !$hasMsys2) {
    Write-Host ""
    Write-Host "Downloading MSYS2 to $msys2ExePath..." -ForegroundColor Cyan
    try {
        Download-File -Url $msys2Url -Destination $msys2ExePath
        Write-Host " - Installing MSYS2 to $msys2InstallDir"
        Start-Process -FilePath $msys2ExePath -ArgumentList "-y", "-o$installBaseDir\" -Wait -ErrorAction Stop
        Remove-Item $msys2ExePath -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Failed to download or install MSYS2: $_"
        Stop-Transcript | Out-Null
        exit 1
    }
}

if (!$hasUpx -and (Test-Path $msys2InstallDir)) {
    Write-Host ""
    Write-Host "Initializing MSYS2 environment..." -ForegroundColor Cyan
    try {
        $env:CHERE_INVOKING = 'yes'
        $env:MSYSTEM = 'UCRT64'
        $pacmanOutLog = Join-Path $logsDir "pacman_out.log"
        $pacmanErrLog = Join-Path $logsDir "pacman_err.log"
        Start-Process -FilePath $bashPath -ArgumentList "-lc", "' '" -Wait
        Write-Host " - Updating MSYS2 and installing dependencies"
        $requiredPackages = @("mingw-w64-ucrt-x86_64-gcc", "mingw-w64-ucrt-x86_64-make", "mingw-w64-ucrt-x86_64-cmake", "mingw-w64-ucrt-x86_64-zlib")
        $missingPackages = @()
        foreach ($pkg in $requiredPackages) {
            $checkOutput = & $bashPath -lc "pacman -Qs $pkg"
            if (-not $checkOutput) {
                $missingPackages += $pkg
            }
        }
        $pacmanCmds = @("pacman -Syu --noconfirm")
        if ($missingPackages.Count -gt 0) {
            $installCmd = "pacman -S --needed --noconfirm " + ($missingPackages -join " ")
            $pacmanCmds += $installCmd
        }
        else {
            Write-Host " - All required packages are already installed. Skipping installation." -ForegroundColor Green
        }
        foreach ($cmd in $pacmanCmds) {
            Write-Host " - Running: $cmd"
            $process = Start-Process -FilePath $bashPath -ArgumentList "-lc", "'$cmd'" -Wait -PassThru -RedirectStandardOutput $pacmanOutLog -RedirectStandardError $pacmanErrLog
            if ($process.ExitCode -ne 0) {
                Write-Error "Command failed: $cmd. Check $pacmanErrLog for details."
                Stop-Transcript | Out-Null
                exit 1
            }
        }
        $allInstalled = $true
        foreach ($pkg in $requiredPackages) {
            $checkOutput = & $bashPath -lc "pacman -Qs $pkg"
            if (-not $checkOutput) {
                $allInstalled = $false
                break
            }
        }
        if (-not $allInstalled) {
            Write-Error "Required packages not installed. Check $pacmanErrLog."
            Stop-Transcript | Out-Null
            exit 1
        }
    }
    catch {
        Write-Error "Failed to initialize or update MSYS2: $_"
        Stop-Transcript | Out-Null
        exit 1
    }
}

if (!$hasUpx) {
    Write-Host ""
    Write-Host "Building UPX..." -ForegroundColor Cyan
    try {
        $upxSrcDir = Get-ChildItem -Path $upxDir -Directory | Where-Object { $_.Name -match '^upx.*src$' } | Select-Object -First 1
        if (-not $upxSrcDir) {
            $upxTarGz = Get-ChildItem -Path $upxDir -File | Where-Object { $_.Name -match '^upx.*src\.tar\.gz$' } | Select-Object -First 1
            if (-not $upxTarGz) {
                Write-Error "No UPX source directory or tar.gz file found in $upxDir."
                Stop-Transcript | Out-Null
                exit 1
            }
            Write-Host " - Extracting source: $($upxTarGz.Name)"
            $tarExe = "tar.exe"
            if (-not (Get-Command $tarExe -ErrorAction SilentlyContinue)) {
                Write-Error "tar.exe not found on the system. Required to extract .tar.gz files."
                Stop-Transcript | Out-Null
                exit 1
            }
            $tarOutLog = Join-Path $logsDir "tar_out.log"
            $tarErrLog = Join-Path $logsDir "tar_err.log"
            $tarPath = $upxTarGz.FullName
            $process = Start-Process -FilePath $tarExe -ArgumentList "-xzf `"$tarPath`"" -WorkingDirectory $upxDir -Wait -PassThru -RedirectStandardOutput $tarOutLog -RedirectStandardError $tarErrLog
            if ($process.ExitCode -ne 0) {
                Write-Error "Failed to extract $tarPath. Check $tarErrLog for details."
                Stop-Transcript | Out-Null
                exit 1
            }
            $upxSrcDir = Get-ChildItem -Path $upxDir -Directory | Where-Object { $_.Name -match '^upx.*src$' } | Select-Object -First 1
            if (-not $upxSrcDir) {
                Write-Error "UPX source directory not found in $upxDir after extraction."
                Stop-Transcript | Out-Null
                exit 1
            }
        }
        $upxSrcDir = $upxSrcDir.FullName
        Write-Host " - Found UPX source directory: $upxSrcDir"
        $upxBuildDir = Join-Path $upxSrcDir "build\release"
        if (-not (Test-Path $upxSrcDir)) {
            Write-Error "UPX source directory $upxSrcDir not found."
            Stop-Transcript | Out-Null
            exit 1
        }
        New-Item -Path $upxBuildDir -ItemType Directory -Force | Out-Null
        $env:CHERE_INVOKING = 'yes'
        $env:MSYSTEM = 'UCRT64'
        $cmakeCmd = "cmake ../.. -G `"MinGW Makefiles`" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS=`"-Os -flto`" DCMAKE_CXX_FLAGS=`"-Os -flto`" -DCMAKE_EXE_LINKER_FLAGS=`"-static-libgcc -static-libstdc++ -static -s -flto`""
        $makeCmd = "mingw32-make"
        $cmakeOutLog = Join-Path $logsDir "cmake_out.log"
        $cmakeErrLog = Join-Path $logsDir "cmake_err.log"
        $makeOutLog = Join-Path $logsDir "make_out.log"
        $makeErrLog = Join-Path $logsDir "make_err.log"
        $upxBuildDirMsys = $upxBuildDir -replace '\\', '/' -replace '^([A-Za-z]):', '/$1'
        Write-Host " - Running cmake"
        $process = Start-Process -FilePath $bashPath -ArgumentList "-lc", "'cd `"$upxBuildDirMsys`" && $cmakeCmd'" -Wait -PassThru -RedirectStandardOutput $cmakeOutLog -RedirectStandardError $cmakeErrLog
        if ($process.ExitCode -ne 0) {
            Write-Error "CMake configuration failed for UPX. Check $cmakeErrLog."
            Stop-Transcript | Out-Null
            exit 1
        }
        Write-Host " - Running mingw32-make"
        $process = Start-Process -FilePath $bashPath -ArgumentList "-lc", "'cd `"$upxBuildDirMsys`" && $makeCmd'" -Wait -PassThru -RedirectStandardOutput $makeOutLog -RedirectStandardError $makeErrLog
        if ($process.ExitCode -ne 0) {
            Write-Error "Make failed for UPX. Check $makeErrLog."
            Stop-Transcript | Out-Null
            exit 1
        }
        $upxExe = Join-Path $upxBuildDir "upx.exe"
        if (-not (Test-Path $upxExe)) {
            Write-Error "UPX executable not found at $upxExe."
            Stop-Transcript | Out-Null
            exit 1
        }
        Copy-Item -Path $upxExe -Destination $genpDir -Force
        Write-Host " - UPX built and copied to $genpDir" -ForegroundColor Green
        Remove-Item -Path (Join-Path $upxSrcDir "build") -Recurse -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Failed to build UPX: $_"
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
    Write-Host "Downloading AutoIt Portable to $autoItZipPath..." -ForegroundColor Cyan
    try {
        Download-File -Url $autoItUrl -Destination $autoItZipPath
        Write-Host " - Extracting AutoIt Portable to $autoItInstallDir"
        Expand-Archive -Path $autoItZipPath -DestinationPath $autoItInstallDir -Force -ErrorAction Stop
        Remove-Item $autoItZipPath -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Failed to download or extract AutoIt Portable: $_"
        Stop-Transcript | Out-Null
        exit 1
    }
}

if (!$hasSciTE) {
    Write-Host ""
    Write-Host "Downloading SciTE Portable to $sciTEZipPath..." -ForegroundColor Cyan
    try {
        Download-File -Url $sciTEUrl -Destination $sciTEZipPath
        Write-Host " - Extracting SciTE Portable to $autoItInstallDir\install\SciTE"
        Expand-Archive -Path $sciTEZipPath -DestinationPath (Join-Path $autoItInstallDir "install\SciTE") -Force -ErrorAction Stop
        Remove-Item $sciTEZipPath -Force -ErrorAction SilentlyContinue
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
