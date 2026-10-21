param([switch]$PreviewOnly, [string]$ReportPath, [string]$CallerPath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-CleanPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -notmatch '^[A-Za-z]:\\') { throw "Invalid cleanup path: $Path" }
    $full = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    if ($full -eq [IO.Path]::GetPathRoot($full).TrimEnd('\')) { throw 'A drive root cannot be cleaned.' }
    return $full
}

function Test-UnderPath([string]$Path, [string]$Root) {
    $p = Get-CleanPath $Path
    $r = Get-CleanPath $Root
    return $p.Equals($r, [StringComparison]::OrdinalIgnoreCase) -or $p.StartsWith($r + '\', [StringComparison]::OrdinalIgnoreCase)
}

function Assert-NoLinkedAncestor([string]$Path) {
    if ($Path -notmatch '^[A-Za-z]:\\') { throw "Invalid local path: $Path" }
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked path requires manual review: $cursor" }
        }
        $cursor = Split-Path -Path $cursor -Parent
    }
}

function Get-SafeTree([string]$Root) {
    Assert-NoLinkedAncestor $Root
    $pending = New-Object 'Collections.Generic.Stack[string]'
    $pending.Push($Root)
    while ($pending.Count) {
        $item = Get-Item -LiteralPath $pending.Pop() -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked item requires manual review: $($item.FullName)" }
        $item
        if ($item.PSIsContainer) {
            foreach ($child in @(Get-ChildItem -LiteralPath $item.FullName -Force)) { $pending.Push($child.FullName) }
        }
    }
}

function Get-AdobeCleanPlan {
    $roots = New-Object 'Collections.Generic.List[string]'
    foreach ($base in @($env:ProgramW6432, $env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($base) { $roots.Add((Join-Path $base 'Adobe')); $roots.Add((Join-Path $base 'Common Files\Adobe')) }
    }
    foreach ($base in @($env:APPDATA, $env:LOCALAPPDATA, $env:ProgramData)) {
        if ($base) { $roots.Add((Join-Path $base 'Adobe')) }
    }
    $roots.Add((Join-Path $env:USERPROFILE 'AppData\LocalLow\Adobe'))
    foreach ($name in @('Adobe', 'CreativeCloud')) { $roots.Add((Join-Path $env:TEMP $name)) }
    $files = New-Object 'Collections.Generic.List[string]'
    $files.Add((Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\Adobe Creative Cloud.lnk'))
    $prefetch = Join-Path $env:SystemRoot 'Prefetch'
    if (Test-Path -LiteralPath $prefetch) {
        foreach ($file in @(Get-ChildItem -LiteralPath $prefetch -File -Force)) {
            if ($file.Name -match '^(ADOBE[^\\]*|CCXPROCESS\.EXE|CREATIVE CLOUD[^\\]*|CRLOGTRANSPORT\.EXE|CRWINDOWSCLIENTSERVICE\.EXE)-[A-F0-9]+\.pf$') { $files.Add($file.FullName) }
        }
    }
    $registry = New-Object 'Collections.Generic.List[object]'
    $seen = @{}
    function Add-RegistryTarget([string]$Key, [string]$Value = '') {
        $identity = $Key + '|' + $Value
        if (-not $seen.ContainsKey($identity) -and (Test-Path -LiteralPath ('Registry::' + $Key))) {
            $seen[$identity] = $true
            $registry.Add([pscustomobject]@{ Key = $Key; Value = $Value })
        }
    }
    foreach ($hive in @('HKEY_LOCAL_MACHINE', 'HKEY_CURRENT_USER')) {
        foreach ($suffix in @('SOFTWARE\Adobe', 'SOFTWARE\WOW6432Node\Adobe', 'SOFTWARE\Policies\Adobe', 'SOFTWARE\WOW6432Node\Policies\Adobe')) {
            Add-RegistryTarget "$hive\$suffix"
        }
        foreach ($prefix in @('SOFTWARE', 'SOFTWARE\WOW6432Node')) {
            $uninstall = "$hive\$prefix\Microsoft\Windows\CurrentVersion\Uninstall"
            if (Test-Path -LiteralPath "Registry::$uninstall") {
                foreach ($entry in @(Get-ChildItem -LiteralPath "Registry::$uninstall")) {
                    $publisher = [string]$entry.GetValue('Publisher')
                    if ($publisher -match '^Adobe(?:\s|$)') {
                        Add-RegistryTarget $entry.Name
                        # Only the Creative Cloud product folder is accepted from registry discovery.
                        $location = [string]$entry.GetValue('InstallLocation')
                        if ($location -match '^[A-Za-z]:\\' -and (Split-Path ($location.TrimEnd('\')) -Leaf) -eq 'Adobe Creative Cloud') {
                            $roots.Add((Get-CleanPath $location))
                        }
                    }
                }
            }
            $run = "$hive\$prefix\Microsoft\Windows\CurrentVersion\Run"
            if (Test-Path -LiteralPath "Registry::$run") {
                $runKey = Get-Item -LiteralPath "Registry::$run"
                foreach ($name in $runKey.GetValueNames()) {
                    if ($name -in @('Adobe Creative Cloud', 'Adobe CCXProcess', 'AdobeGCInvoker-1.0')) { Add-RegistryTarget $run $name }
                }
            }
        }
        $classes = "$hive\SOFTWARE\Classes"
        foreach ($entry in @(Get-ChildItem -LiteralPath "Registry::$classes")) {
            if ($entry.PSChildName -match '^Adobe(?:\.|AAMDetect|CreativeCloud|Acrobat|ARM)') { Add-RegistryTarget $entry.Name }
        }
    }
    # Exact COM/type library registrations supplied in the BCUninstaller export.
    foreach ($id in @('{2A118EB5-5797-4F5E-8B3D-F4ECBA3C98E4}', '{42D38F2E-98E9-4382-B546-E24E4D6D04BB}', '{853B7E05-C47D-4985-909A-D0DC5C6D7303}', '{AB9CF9F8-8A96-4F9D-BF21-CE85714C3A47}')) {
        Add-RegistryTarget "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\$id"
    }
    foreach ($suffix in @('CLSID\{e8c77137-e224-5791-b6e9-ff0305797a13}', 'WOW6432Node\CLSID\{e8c77137-e224-5791-b6e9-ff0305797a13}', 'TypeLib\{AF13F923-A232-5DA3-B24E-6E5E13E42B49}')) {
        Add-RegistryTarget "HKEY_CURRENT_USER\SOFTWARE\Classes\$suffix"
    }
    foreach ($id in @('{3956A7FA-824C-4184-871C-739C40164CAC}', '{59E9A4A9-40E1-4CE6-B939-EE46EBA237C1}')) {
        foreach ($prefix in @('TypeLib', 'WOW6432Node\TypeLib')) { Add-RegistryTarget "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\$prefix\$id" }
    }
    foreach ($prefix in @('SOFTWARE', 'SOFTWARE\WOW6432Node')) {
        Add-RegistryTarget "HKEY_LOCAL_MACHINE\$prefix\MozillaPlugins\adobe.com/AdobeAAMDetect"
        $acc = "Registry::HKEY_LOCAL_MACHINE\$prefix\Adobe\Adobe Application Manager\ACC"
        if (Test-Path -LiteralPath $acc) {
            $location = [string](Get-Item -LiteralPath $acc).GetValue('InstallLocation')
            if ($location -match '^[A-Za-z]:\\' -and (Split-Path ($location.TrimEnd('\')) -Leaf) -eq 'Adobe Creative Cloud') { $roots.Add((Get-CleanPath $location)) }
        }
    }
    $compat = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store'
    if (Test-Path -LiteralPath "Registry::$compat") {
        foreach ($name in (Get-Item -LiteralPath "Registry::$compat").GetValueNames()) {
            if ($name -match '^[A-Za-z]:\\' -and @($roots | Where-Object { Test-UnderPath $name $_ }).Count) { Add-RegistryTarget $compat $name }
        }
    }
    $allRoots = @($roots | ForEach-Object { Get-CleanPath $_ } | Sort-Object -Unique)
    $selected = @($allRoots | Where-Object {
        $candidate = $_
        -not @($allRoots | Where-Object { $_ -ne $candidate -and (Test-UnderPath $candidate $_) }).Count
    })
    $services = @(Get-CimInstance Win32_Service | Where-Object {
        $binary = [string]$_.PathName
        ($_.Name -match '^(Adobe|AGSService$|AGMService$)' -and $binary -match '(?i)\\Adobe\\')
    })
    foreach ($service in $services) { Add-RegistryTarget ('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\' + $service.Name) }
    # Task actions are evaluated explicitly below: do not match shared task names by substring.
    $tasks = @(Get-ScheduledTask | Where-Object {
        $owned = $false
        foreach ($action in $_.Actions) {
            if (-not $action.PSObject.Properties['Execute']) { continue }
            $exe = ([string]$action.Execute).Trim('"')
            if ($exe -match '^[A-Za-z]:\\') { foreach ($root in $selected) { if (Test-UnderPath $exe $root) { $owned = $true } } }
        }
        $owned
    })
    $packages = @(Get-AppxPackage -Name 'AdobeNotificationClient' | Where-Object Publisher -match 'O=Adobe (Inc\.|Systems Incorporated)(,|$)')
    [pscustomobject]@{ Roots = $selected; Files = @($files); Registry = @($registry.ToArray()); Services = $services; Tasks = $tasks; Packages = $packages }
}

function Initialize-CleanFileEngine {
    if ('GenP.AdobeCleanupTree' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Collections.Generic;
namespace GenP {
    public static class AdobeCleanupTree {
        private sealed class Batch {
            public DirectoryInfo Directory;
            public List<FileInfo> Files = new List<FileInfo>();
        }
        private static void CheckLink(string path, FileAttributes attributes) {
            if ((attributes & FileAttributes.ReparsePoint) != 0)
                throw new IOException("Linked path requires manual review: " + path);
        }
        private static void CheckAncestors(string path) {
            for (DirectoryInfo entry = new DirectoryInfo(path); entry != null; entry = entry.Parent)
                CheckLink(entry.FullName, entry.Attributes);
        }
        private static bool Missing(Exception error) {
            return error is FileNotFoundException || error is DirectoryNotFoundException;
        }
        private static void DeleteFile(string path, List<string> errors) {
            try {
                FileAttributes attributes = File.GetAttributes(path);
                CheckLink(path, attributes);
                if ((attributes & FileAttributes.Directory) != 0)
                    throw new IOException("File changed into a directory: " + path);
                if ((attributes & FileAttributes.ReadOnly) != 0)
                    File.SetAttributes(path, attributes & ~FileAttributes.ReadOnly);
                File.Delete(path);
            } catch (Exception error) { if (!Missing(error)) errors.Add(path + ": " + error.Message); }
        }
        public static string[] Remove(string path) {
            var errors = new List<string>();
            FileAttributes attributes;
            try { attributes = File.GetAttributes(path); }
            catch (Exception error) { if (Missing(error)) return errors.ToArray(); throw; }
            CheckLink(path, attributes);
            if ((attributes & FileAttributes.Directory) == 0) {
                CheckAncestors(Path.GetDirectoryName(path));
                DeleteFile(path, errors);
                return errors.ToArray();
            }
            CheckAncestors(path);
            var pending = new Stack<DirectoryInfo>();
            var batches = new List<Batch>();
            pending.Push(new DirectoryInfo(path));
            // Validate the full tree before deleting anything; never traverse reparse points.
            while (pending.Count != 0) {
                DirectoryInfo directory = pending.Pop();
                CheckLink(directory.FullName, directory.Attributes);
                var batch = new Batch { Directory = directory };
                foreach (FileSystemInfo entry in directory.EnumerateFileSystemInfos()) {
                    CheckLink(entry.FullName, entry.Attributes);
                    if ((entry.Attributes & FileAttributes.Directory) != 0)
                        pending.Push((DirectoryInfo)entry);
                    else batch.Files.Add((FileInfo)entry);
                }
                batches.Add(batch);
            }
            foreach (Batch batch in batches) {
                try { CheckAncestors(batch.Directory.FullName); }
                catch (Exception error) {
                    if (!Missing(error)) errors.Add(batch.Directory.FullName + ": " + error.Message);
                    continue;
                }
                // Validate shared ancestors once per directory, rather than once per file.
                foreach (FileInfo file in batch.Files) DeleteFile(file.FullName, errors);
            }
            for (int i = batches.Count - 1; i >= 0; --i) {
                string directory = batches[i].Directory.FullName;
                try {
                    CheckAncestors(directory);
                    FileAttributes current = File.GetAttributes(directory);
                    CheckLink(directory, current);
                    if ((current & FileAttributes.ReadOnly) != 0)
                        File.SetAttributes(directory, current & ~FileAttributes.ReadOnly);
                    // Nonrecursive: new or locked files cause a reported failure.
                    Directory.Delete(directory, false);
                } catch (Exception error) { if (!Missing(error)) errors.Add(directory + ": " + error.Message); }
            }
            return errors.ToArray();
        }
    }
}
'@
}

function Remove-ScopedTree([string]$Path) {
    $full = Get-CleanPath $Path
    Assert-NoLinkedAncestor $full
    Initialize-CleanFileEngine
    $errors = @([GenP.AdobeCleanupTree]::Remove($full))
    if ($errors.Count) { throw [IO.IOException]::new(($errors -join [Environment]::NewLine)) }
    if (Test-Path -LiteralPath $full) { throw [IO.IOException]::new("Still present: $full") }
}

function Remove-ScopedTreeWithRetry([string]$Path, [scriptblock]$OnRetry = {}, [int]$Attempts = 3, [int]$DelayMilliseconds = 200) {
    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try { Remove-ScopedTree $Path; return }
        catch {
            if ($attempt -eq $Attempts) { throw }
            Start-Sleep -Milliseconds $DelayMilliseconds
            # Release locks immediately before the next attempt, after the short delay.
            & $OnRetry $attempt ([string]$_)
        }
    }
}

function Get-CleanLogDirectory([string]$ExecutablePath) {
    if ($ExecutablePath) { return [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($ExecutablePath)) }
    return $PSScriptRoot
}

function Test-AdobeCommonRoot([string]$Path) {
    $full = Get-CleanPath $Path
    foreach ($base in @($env:ProgramW6432, $env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($base -and $full.Equals((Get-CleanPath (Join-Path $base 'Common Files\Adobe')), [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function Stop-CleanExplorer {
    $session = (Get-Process -Id $PID).SessionId
    foreach ($process in @(Get-Process explorer -ErrorAction SilentlyContinue | Where-Object SessionId -eq $session)) {
        $script:CleanExplorerStopped = $true
        Stop-Process -Id $process.Id -Force
        if (-not $process.WaitForExit(2000)) { throw "Explorer did not exit: $($process.Id)" }
    }
}

function Resume-CleanExplorer {
    if (-not $script:CleanExplorerStopped) { return }
    $session = (Get-Process -Id $PID).SessionId
    $running = @(Get-Process explorer -ErrorAction SilentlyContinue | Where-Object SessionId -eq $session)
    if (-not $running.Count) { Start-Process -FilePath "$env:SystemRoot\explorer.exe" -WindowStyle Normal }
    $script:CleanExplorerStopped = $false
}

function Remove-AdobeRegistryEntry($Entry) {
    $parts = $Entry.Key -split '\\', 2
    $hiveId = switch ($parts[0]) {
        'HKEY_LOCAL_MACHINE' { [Microsoft.Win32.RegistryHive]::LocalMachine }
        'HKEY_CURRENT_USER' { [Microsoft.Win32.RegistryHive]::CurrentUser }
        default { throw "Unsupported registry hive: $($parts[0])" }
    }
    $hive = [Microsoft.Win32.RegistryKey]::OpenBaseKey($hiveId, [Microsoft.Win32.RegistryView]::Registry64)
    try {
        if ($Entry.Value) {
            $key = $hive.OpenSubKey($parts[1], $true)
            if ($null -eq $key) { return }
            try { $key.DeleteValue($Entry.Value, $false) } finally { $key.Dispose() }
        } else { $hive.DeleteSubKeyTree($parts[1], $false) }
    } finally { $hive.Dispose() }
}

function Show-CleanMessage([string]$Text, [string]$Buttons = 'OK', [string]$Icon = 'Information') {
    return [Windows.Forms.MessageBox]::Show($Text, 'GenP - Full Adobe Clean', $Buttons, $Icon, [Windows.Forms.MessageBoxDefaultButton]::Button1)
}

function Invoke-FullAdobeClean {
    Add-Type -AssemblyName System.Windows.Forms
    if (-not [Environment]::Is64BitProcess) { throw 'Use 64-bit Windows PowerShell for both registry views.' }
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Run GenP as administrator.' }
    $intro = "I would use BCUninstaller first, then use this clean option. Doing it manually is okay too.`r`n`r`nThis permanently removes the listed Adobe applications, shared components, settings, caches, and registry entries for this Windows user and this machine. No backup or restore point will be created. Other Windows users are not cleaned.`r`n`r`nAdobe processes and services will be terminated. Explorer will be stopped while Adobe shared files are deleted, then restarted. The desktop/taskbar and open folder windows may close. Save all work first.`r`n`r`nCleanup logs are saved beside the GenP executable.`r`n`r`nContinue to review the targets?"
    if ([Windows.Forms.MessageBox]::Show($intro, 'GenP - Full Adobe Clean', 'OKCancel', 'Warning', 'Button2') -ne 'OK') { return 2 }
    $plan = Get-AdobeCleanPlan
    foreach ($root in $plan.Roots) { if (Test-UnderPath $PSCommandPath $root) { throw 'Move GenP outside the Adobe folders before cleaning.' } }
    if ($CallerPath) { foreach ($root in $plan.Roots) { if (Test-UnderPath $CallerPath $root) { throw 'Move GenP outside the Adobe folders before cleaning.' } } }
    $preview = New-Object Windows.Forms.Form
    $preview.Text = 'Full Adobe Clean - review targets'
    $preview.Size = New-Object Drawing.Size(760, 570)
    $preview.StartPosition = 'CenterScreen'
    $text = New-Object Windows.Forms.TextBox
    $text.Multiline = $true; $text.ReadOnly = $true; $text.ScrollBars = 'Both'; $text.WordWrap = $false
    $text.SetBounds(12, 12, 720, 450)
    $lines = @('PERMANENT REMOVAL - NO BACKUP OR RESTORE POINT', '', 'Folders (including Creative Cloud):') + $plan.Roots + $plan.Files + @('', 'Registry (keys or individual values):') + @($plan.Registry | ForEach-Object { $_.Key + $(if ($_.Value) { ' => ' + $_.Value }) }) + @('', 'Services:') + @($plan.Services | ForEach-Object Name) + @('', 'Scheduled tasks:') + @($plan.Tasks | ForEach-Object { $_.TaskPath + $_.TaskName }) + @('', 'Windows notification packages:') + @($plan.Packages | ForEach-Object PackageFullName)
    $text.Text = $lines -join "`r`n"
    $go = New-Object Windows.Forms.Button; $go.Text = 'Clean now'; $go.SetBounds(400, 480, 160, 32); $go.DialogResult = 'OK'
    $cancel = New-Object Windows.Forms.Button; $cancel.Text = 'Cancel'; $cancel.SetBounds(580, 480, 130, 32); $cancel.DialogResult = 'Cancel'
    $preview.Controls.AddRange(@($text, $go, $cancel)); $preview.CancelButton = $cancel; $preview.AcceptButton = $cancel
    try { if ($preview.ShowDialog() -ne 'OK') { return 2 } } finally { $preview.Dispose() }
    $logDirectory = Get-CleanLogDirectory $CallerPath
    Assert-NoLinkedAncestor $logDirectory
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    $script:CleanLog = Join-Path $logDirectory ('AdobeClean-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N') + '.log')
    $failures = New-Object 'Collections.Generic.List[string]'
    function Write-CleanLog([string]$Message) { Add-Content -LiteralPath $script:CleanLog -Value ((Get-Date -Format o) + ' ' + $Message) }
    $progress = New-Object Windows.Forms.Form; $progress.Text = 'GenP - Full Adobe Clean'; $progress.Size = New-Object Drawing.Size(640, 130); $progress.StartPosition = 'CenterScreen'; $progress.ControlBox = $false
    $label = New-Object Windows.Forms.Label; $label.SetBounds(15, 20, 600, 60); $progress.Controls.Add($label); $progress.Show()
    function Set-CleanProgress([string]$Message) { $label.Text = $Message; [Windows.Forms.Application]::DoEvents(); Write-CleanLog $Message }
    $script:CleanExplorerStopped = $false
    $deletionStarted = $false
    $stoppedServices = New-Object 'Collections.Generic.List[string]'
    $disabledTasks = New-Object 'Collections.Generic.List[object]'
    try {
        Set-CleanProgress 'Stopping Adobe services and scheduled tasks...'
        foreach ($service in $plan.Services) {
            $dependent = @((Get-Service -Name $service.Name).DependentServices | Where-Object Status -ne 'Stopped')
            if ($dependent.Count) { throw "Stop dependent services manually before cleaning $($service.Name): $($dependent.Name -join ', ')" }
        }
        foreach ($task in $plan.Tasks) {
            if ($task.State -ne 'Disabled') { Disable-ScheduledTask -InputObject $task | Out-Null; $disabledTasks.Add($task) }
            Stop-ScheduledTask -InputObject $task
        }
        foreach ($service in $plan.Services) {
            if ($service.State -eq 'Running') {
                $stoppedServices.Add($service.Name)
                Stop-Service -Name $service.Name
                (Get-Service -Name $service.Name).WaitForStatus('Stopped', [TimeSpan]::FromSeconds(30))
            }
        }
        Set-CleanProgress 'Closing Adobe processes...'
        foreach ($process in @(Get-CimInstance Win32_Process)) {
            $exe = [string]$process.ExecutablePath
            if ($process.ProcessId -eq $PID -or $exe -notmatch '^[A-Za-z]:\\') { continue }
            foreach ($root in $plan.Roots) {
                if (Test-UnderPath $exe $root) { Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue; break }
            }
        }
        # Compile before stopping Explorer to keep the shell interruption short.
        Initialize-CleanFileEngine
        # The confirmation above authorizes a brief shell restart for shared Adobe files.
        # Keep both Common Files roots together so Explorer is restarted only once.
        $commonRoots = @($plan.Roots | Where-Object { Test-AdobeCommonRoot $_ })
        $otherRoots = @($plan.Roots | Where-Object { -not (Test-AdobeCommonRoot $_) })
        $lastCommon = $(if ($commonRoots.Count) { $commonRoots[-1] } else { '' })
        $deletionStarted = $true
        foreach ($root in $commonRoots + $otherRoots + @($plan.Files)) {
            $isCommon = Test-AdobeCommonRoot $root
            try {
                Set-CleanProgress "Removing:`r`n$root"
                if (Test-Path -LiteralPath $root) {
                    if ($isCommon) { Write-CleanLog "Releasing Explorer locks for: $root"; Stop-CleanExplorer }
                    Remove-ScopedTreeWithRetry $root -OnRetry {
                        param($attempt, $reason)
                        Write-CleanLog "Retry $attempt for $root : $reason"
                        if ($isCommon) { Stop-CleanExplorer }
                    }
                }
            } catch { $failures.Add("Files: $root : $_") }
            finally {
                if ($isCommon -and $root -eq $lastCommon) {
                    try { Resume-CleanExplorer; Write-CleanLog 'Explorer restored after shared-file cleanup.' }
                    catch { $failures.Add("Explorer restart: $_") }
                }
            }
        }
        foreach ($service in $plan.Services) {
            try {
                & "$env:SystemRoot\System32\sc.exe" delete $service.Name | Out-Null
                if ($LASTEXITCODE -ne 0) { throw "Service deletion failed: $($service.Name)" }
            } catch { $failures.Add("Service: $_") }
        }
        foreach ($task in $plan.Tasks) {
            try { Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Confirm:$false }
            catch { $failures.Add("Task: $($task.TaskName): $_") }
        }
        foreach ($entry in $plan.Registry) {
            # Service Control Manager owns service removal; do not directly erase service keys.
            if ($entry.Key -like 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\*') { continue }
            try {
                Remove-AdobeRegistryEntry $entry
            } catch { $failures.Add("Registry: $_") }
        }
        foreach ($package in $plan.Packages) {
            try { Remove-AppxPackage -Package $package.PackageFullName }
            catch { $failures.Add("Notification package: $_") }
        }
        Set-CleanProgress 'Verifying remaining folders, registry entries, services and tasks...'
        $remaining = Get-AdobeCleanPlan
        foreach ($root in @(@($plan.Roots) + @($plan.Files) + @($remaining.Roots) + @($remaining.Files) | Sort-Object -Unique)) { if (Test-Path -LiteralPath $root) { $failures.Add("Still present: $root") } }
        foreach ($entry in $remaining.Registry) { $failures.Add("Registry remains: $($entry.Key) $($entry.Value)") }
        foreach ($service in $remaining.Services) { $failures.Add("Service remains (may need reboot): $($service.Name)") }
        foreach ($task in $remaining.Tasks) { $failures.Add("Task remains: $($task.TaskName)") }
        foreach ($package in $remaining.Packages) { $failures.Add("Package remains: $($package.PackageFullName)") }
        $uniqueFailures = @($failures | Sort-Object -Unique)
        $status = $(if ($uniqueFailures.Count) { 'Partial' } else { 'Complete' })
        foreach ($failure in $uniqueFailures) { Write-CleanLog $failure }
        Write-CleanLog "Cleanup: $status"
        $progress.Hide()
        $message = "Cleanup: $status`r`nFull results:`r`n$script:CleanLog`r`n`r`nRestart Windows before reinstalling Creative Cloud."
        if ($uniqueFailures.Count) { $message += "`r`n`r`nRemaining items/errors: $($uniqueFailures.Count). Review the log and retry locked files after reboot." }
        $message += "`r`n`r`nIf Retry continues, keep the error code and review installer logs. Existing GenP hosts/firewall/proxy settings can also affect downloads; review those tabs before reinstalling."
        Show-CleanMessage $message | Out-Null
        if ($uniqueFailures.Count) { return 1 }; return 0
    } catch {
        Write-CleanLog "Failed: $_"
        throw "Cleanup stopped: $_ `r`nResults: $script:CleanLog"
    } finally {
        try {
            Resume-CleanExplorer
            if (-not $deletionStarted) {
                foreach ($name in $stoppedServices) { try { Start-Service -Name $name } catch { Write-CleanLog "Could not restart $name : $_" } }
                foreach ($task in $disabledTasks) { try { Enable-ScheduledTask -InputObject $task | Out-Null } catch { Write-CleanLog "Could not re-enable task: $_" } }
            }
        } finally { $progress.Close(); $progress.Dispose() }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        if ($PreviewOnly) {
            $plan = Get-AdobeCleanPlan
            $json = $plan | ConvertTo-Json -Depth 8
            if ($ReportPath) { $json | Set-Content -LiteralPath $ReportPath -Encoding UTF8 } else { $json }
            exit 0
        }
        exit (Invoke-FullAdobeClean)
    } catch {
        Add-Type -AssemblyName System.Windows.Forms
        Show-CleanMessage ([string]$_) 'OK' 'Error' | Out-Null
        exit 1
    }
}
