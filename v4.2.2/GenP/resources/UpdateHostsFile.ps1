$scriptDir = "C:\Windows\System32\drivers\etc"
$logDirectory = "C:\Windows\System32\drivers\etc"
$logFile = "$logDirectory\UpdateHostsFile.log"
if (-not (Test-Path -Path $logDirectory)) { New-Item -ItemType Directory -Path $logDirectory -Force }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Content -Path $logFile -Value $null
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logEntry
}
function Test-IsAdmin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "This script requires administrative privileges. Please run PowerShell as Administrator."
        Write-Output "This script requires administrative privileges. Please run PowerShell as Administrator."
        exit
    }
}
function SafeFileOperation {
    param (
        [string]$Action,
        [string]$Source,
        [string]$Destination
    )
    try {
        switch ($Action) {
            "Copy" { Copy-Item -Path $Source -Destination $Destination -Force }
            "Rename" { Rename-Item -Path $Source -NewName $Destination -Force }
        }
        Write-Log "$Action operation successful: $Source -> $Destination"
    } catch {
        Write-Log "Failed to $Action file: Please ensure the source file exists and you have the necessary permissions."
    }
}
Test-IsAdmin
Write-Log "Script execution started."
$hostsFile = "C:\Windows\System32\drivers\etc\hosts"
$backupCurrent = "C:\Windows\System32\drivers\etc\hosts.bak"
$plainBackup = "C:\Windows\System32\drivers\etc\hosts.plain"
$tempFile = "$scriptDir\hosts_temp"
$primaryGenPPath = "__GENP_PATH__"
if (-not (Test-Path $hostsFile)) {
    Write-Log "The hosts file does not exist at the specified path: $hostsFile"
    exit
}
if (-not (Test-Path $primaryGenPPath)) {
    Write-Log "The specified GenP executable does not exist at: $primaryGenPPath"
    exit
}
if ((Get-Item $hostsFile).Attributes -band [System.IO.FileAttributes]::ReadOnly) {
    Write-Log "The hosts file is currently read-only. Attempting to remove read-only attribute."
    try {
        Set-ItemProperty -Path $hostsFile -Name IsReadOnly -Value $false
        Write-Log "Removed read-only attribute from the hosts file."
    } catch {
        Write-Log "Could not change the read-only status of the hosts file. Please check permissions."
    }
}
$currentContent = Get-Content -Path $hostsFile -Raw -ErrorAction SilentlyContinue
if (-not (Test-Path $backupCurrent) -or ($currentContent -ne (Get-Content -Path $backupCurrent -Raw -ErrorAction SilentlyContinue))) {
    Write-Log "Creating a new last known good backup of the hosts file."
    SafeFileOperation -Action "Copy" -Source $hostsFile -Destination $backupCurrent
} else {
    Write-Log "No differences detected between the current hosts file and the last known good backup. Skipping backup creation."
}
$hostsContent = Get-Content -Path $hostsFile -Raw -ErrorAction SilentlyContinue
Write-Log "Hosts file content retrieved."
$maxRetries = 3
$retryDelay = 2
$newBlocklist = @()
Write-Log "Attempting to execute GenP.exe for blocklist."
try {
    Start-Process -FilePath $primaryGenPPath -ArgumentList "-updatehosts" -NoNewWindow -Wait
    Write-Log "GenP.exe executed successfully."
    $hostsContent = Get-Content -Path $hostsFile -Raw
    if ($hostsContent -match "^0\.0\.0\.0") {
        Write-Log "GenP.exe output detected and appears structurally valid."
        $newBlocklist = $hostsContent -split "`n" | Where-Object { $_.Trim() -match '^0\.0\.0\.0' }
    } else {
        Write-Log "GenP.exe output missing or invalid."
        throw "Invalid GenP.exe output."
    }
} catch {
    Write-Log "Failed to run GenP to fetch the blocklist; please ensure the executable is present and try again."
}
if (-not $newBlocklist.Count) {
    Write-Log "Attempting to retrieve blocklist from fallback URLs."
    $encodedUrls = @(
        "aHR0cHM6Ly9hLmRvdmUuaXNkdW1iLm9uZS9saXN0LnR4dA==", 
        "aHR0cHM6Ly9hLmRvdmUuaXNkdW1iLm9uZS93aW5ob3N0cy50eHQ=",
        "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2lnbmFjaW9jYXN0cm8vYS1kb3ZlLWlzLWR1bWIvcmVmcy9oZWFkcy9tYWluL2xpc3QudHh0",
        "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2lnbmFjaW9jYXN0cm8vYS1kb3ZlLWlzLWR1bWIvcmVmcy9oZWFkcy9tYWluL3dpbmhvc3RzLnR4dA=="
    )
    foreach ($encodedUrl in $encodedUrls) {
        $decodedUrl = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedUrl))
        Write-Log "Trying to access fallback URL."
        for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
            try {
                Write-Log "Retrieving blocklist content from fallback URL."
                $response = Invoke-WebRequest -Uri $decodedUrl -UseBasicParsing -ErrorAction Stop
                if ($response.Content) {
                    Write-Log "Successfully retrieved content from fallback URL on attempt $attempt."
                    $newBlocklist += $response.Content -split "`n" | Where-Object { $_ -match "^0\.0\.0\.0|^# Last update:" }
                    break
                }
            } catch {
                Write-Log "Failed to connect to the provided URL; please check internet connectivity or the URL itself."
                if ($attempt -lt $maxRetries) {
                    Write-Log "Retrying in $retryDelay seconds."
                    Start-Sleep -Seconds $retryDelay
                }
            }
        }
        if ($newBlocklist.Count -gt 0) { break }
    }
}
if ($newBlocklist.Count -eq 0) {
    Write-Log "No blocklist entries retrieved from any source. Attempting to restore hosts file from hosts.plain."
    if (Test-Path $plainBackup) {
        Write-Log "Restoring hosts file from hosts.plain file."
        $plainContent = Get-Content -Path $plainBackup -Raw -ErrorAction SilentlyContinue
        if (-not [string]::IsNullOrWhiteSpace($plainContent)) {
            Write-Log "Restoring hosts file."
            Set-Content -Path $hostsFile -Value $plainContent -NoNewline
            Write-Log "Successfully restored hosts file from hosts.plain."
        } else {
            Write-Log "hosts.plain is empty or invalid; unable to restore hosts file."
        }
    } else {
        Write-Log "hosts.plain file does not exist; cannot restore hosts file."
        Write-Log "Restoring hosts file from backup."
        SafeFileOperation -Action "Copy" -Source $backupCurrent -Destination $hostsFile
    }
    Write-Log "Exiting script."
    exit
}
Write-Log "Total valid blocklist entries pulled: $($newBlocklist.Count)"
$blocklistHeader = "# START - Adobe Blocklist"
$blocklistFooter = "# END - Adobe Blocklist"
$lastUpdateComment = ""
foreach ($line in $newBlocklist) {
    if ($line.Trim().StartsWith("# Last update:")) {
        $lastUpdateComment = "`n$($line.Trim())"
    }
}
$filteredBlocklist = $newBlocklist | Where-Object { -not ($_.Trim().StartsWith("# Last update:")) -and $_.Trim() -ne "" }
$finalContent = ""
if (Test-Path $plainBackup) {
    $plainContent = Get-Content -Path $plainBackup -Raw -ErrorAction SilentlyContinue
    if (-not [string]::IsNullOrWhiteSpace($plainContent)) {
        Write-Log "Including content from hosts.plain at the top of the hosts file."
        $finalContent += $plainContent.Trim() + "`n"
    } else {
        Write-Log "The file hosts.plain is empty; it will not be included."
    }
}
$finalContent += "$blocklistHeader$lastUpdateComment`n$($filteredBlocklist -join "`n")`n$blocklistFooter".Trim()
$finalContent = $finalContent -replace "`r?`n`r?`n", "`n"
for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
    try {
        Start-Sleep -Seconds 1
        Write-Log "Attempting to write to $tempFile, Attempt #$attempt"
        if ((Get-Item $hostsFile).Attributes -band [System.IO.FileAttributes]::ReadOnly) {
            Write-Log "The hosts file is currently read-only. Attempting to remove read-only attribute."
            Set-ItemProperty -Path $hostsFile -Name IsReadOnly -Value $false
            Write-Log "Removed read-only attribute from hosts file."
        }
        Set-Content -Path $tempFile -Value $finalContent -NoNewline
        Write-Log "Temporary file created successfully."
        SafeFileOperation -Action "Copy" -Source $tempFile -Destination $hostsFile
        Write-Log "Hosts file successfully updated from temporary file."
        break
    } catch {
        Write-Log "An error occurred while updating the hosts file. Ensure you have sufficient permissions."
        if ($errorMsg -like "*denied*") {
            Write-Log "Access to $hostsFile is denied. Retrying in $retryDelay seconds..."
            Start-Sleep -Seconds $retryDelay
        } else {
            Write-Log "An unexpected error occurred: $errorMsg"
            break
        }
    }
}
Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
Write-Log "Script execution completed successfully. Hosts file is in a safe and consistent state."
