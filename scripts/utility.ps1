# Script: scripts\utility.ps1

# Helper: Show-FunctionHeader
# In normal mode: clears screen and shows header.
# In batch mode (Disable All): skips both to keep the running log.
function Show-FunctionHeader {
    if (-not $Global:BatchMode) {
        Clear-Host
        Show-Header
    }
}

# Helper: Confirm-CompatOrBatch
# In normal mode: shows compat warning and asks Y/N.
# In batch mode: shows compat info but skips the prompt (already confirmed).
# Returns $true to proceed, $false to skip.
function Confirm-CompatOrBatch {
    param([string]$HackName)
    if ($Global:BatchMode) {
        # In batch mode, still show the compat note but don't prompt
        $compat = Get-HackCompatibility -VersionInfo $Global:VersionInfo
        $osKey = if ($Global:VersionInfo.OsMajor -ge 11) { "Win11" } else { "Win10" }
        if ($compat.ContainsKey($HackName)) {
            $info = $compat[$HackName][$osKey]
            $color = switch ($info.Status) {
                "works" { "Green" } "safemode" { "Yellow" }
                "limited" { "Yellow" } "ineffective" { "Red" }
                default { "Gray" }
            }
            Write-Host "  [$($Global:VersionInfo.DisplayVersion)] " -NoNewline
            Write-Host "$($info.Status.ToUpper())" -ForegroundColor $color
        }
        return $true
    }
    return (Show-CompatWarning -HackName $HackName -VersionInfo $Global:VersionInfo)
}

# ============================================================
#  DEFENDER FUNCTIONS
# ============================================================

# Function Disable-DefenderRegistry
function Disable-DefenderRegistry {
    Show-FunctionHeader
    Write-Host "Registry Edits..."

    if (-not (Confirm-CompatOrBatch -HackName "Registry")) {
        return
    }

    $entries = Get-DefenderRegistryEntries -VersionInfo $Global:VersionInfo
    $successCount = 0
    $failCount = 0

    foreach ($entry in $entries) {
        Write-Host "..Setting: $($entry.Name)"
        try {
            if (-not (Test-Path $entry.Path)) {
                New-Item -Path $entry.Path -Force | Out-Null
            }
            Set-ItemProperty -Path $entry.Path -Name $entry.Name -Value $entry.Value -Type DWord -ErrorAction Stop

            # Verify
            $check = Get-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
            if ($check.$($entry.Name) -eq $entry.Value) {
                Write-Host "..Verified: $($entry.Name) = $($entry.Value)"
                $successCount++
            } else {
                Write-Host "..Warning: $($entry.Name) value not confirmed (may be tamper-protected)"
                $failCount++
            }
        }
        catch {
            $failCount++
            Log-Error "Registry: $($entry.Name) - $($_.Exception.Message)"
            Write-Host "..Failed: $($entry.Name)"
        }
    }

    Write-Host ""
    Write-Host "...$successCount set, $failCount failed/unconfirmed."
    Write-Host "...Registry Edits Finished."
}

# Function Run-DisableTamperProtection
function Run-DisableTamperProtection {
    Show-FunctionHeader
    Write-Host "Disable Tamper Protection..."

    if (-not (Confirm-CompatOrBatch -HackName "TamperProtection")) {
        return
    }

    try {
        Set-MpPreference -DisableTamperProtection $true -ErrorAction Stop
        Write-Host "..Tamper Protection Disabled."
        Start-Sleep -Seconds 2

        Write-Host "Checking Tamper Protection State..."
        $mpPrefs = Get-MpPreference
        $status = if ($mpPrefs.DisableTamperProtection) { "Disabled" } else { "Enabled" }
        Write-Host "..Tamper Protection Status: $status"
    }
    catch {
        $errorMessage = "Error: $($_.Exception.Message)"
        Log-Error $errorMessage
        Write-Host $errorMessage
        Write-Host "..Skipping State Check."
        Write-Host ""
        Write-Host "  TIP: On Win10/Win11 you may need to disable Tamper" -ForegroundColor Yellow
        Write-Host "  Protection manually via Windows Security GUI first." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 1
}

# Function Run-DisableDefenderFeatures
function Run-DisableDefenderFeatures {
    Show-FunctionHeader
    Write-Host "Disable Defender Features..."

    if (-not (Confirm-CompatOrBatch -HackName "DefenderFeatures")) {
        return
    }

    try {
        Write-Host "..Disabling Low-Threats.."
        Set-MpPreference -LowThreatDefaultAction Allow -ErrorAction SilentlyContinue
        Write-Host "..Disabling Moderate-Threats.."
        Set-MpPreference -ModerateThreatDefaultAction Allow -ErrorAction SilentlyContinue
        Write-Host "..Disabling High-Threats.."
        Set-MpPreference -HighThreatDefaultAction Allow -ErrorAction SilentlyContinue
        Write-Host "..Disabling Severe-Threats.."
        Set-MpPreference -SevereThreatDefaultAction Allow -ErrorAction SilentlyContinue
        Write-Host "..Disabling Realtime-Monitoring.."
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
        Write-Host "..Disabling Behavior-Monitoring.."
        Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
        Write-Host "..Disabling IOAV-Protection.."
        Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
        Write-Host "..Disabling Script-Scanning.."
        Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
        Write-Host "...Defender Features Disabled."
        Start-Sleep -Seconds 2

        Write-Host "Check Features States..."
        $mpPrefs = Get-MpPreference
        Write-Host "..Low Threats: $(Translate-DefenderAction $mpPrefs.LowThreatDefaultAction)"
        Write-Host "..Moderate Threats: $(Translate-DefenderAction $mpPrefs.ModerateThreatDefaultAction)"
        Write-Host "..High Threats: $(Translate-DefenderAction $mpPrefs.HighThreatDefaultAction)"
        Write-Host "..Severe Threats: $(Translate-DefenderAction $mpPrefs.SevereThreatDefaultAction)"
        Write-Host "..Realtime Monitoring Disabled: $($mpPrefs.DisableRealtimeMonitoring)"
        Write-Host "..Behavior Monitoring Disabled: $($mpPrefs.DisableBehaviorMonitoring)"
        Write-Host "..IOAV Protection Disabled: $($mpPrefs.DisableIOAVProtection)"
        Write-Host "...Features States Reported."
        Start-Sleep -Seconds 1
    }
    catch {
        $errorMessage = "Error in Disable-Defender: $($_.Exception.Message)"
        Log-Error $errorMessage
        Write-Host $errorMessage
        Start-Sleep -Seconds 1
    }
}

# Function Translate-DefenderAction
function Translate-DefenderAction {
    param([int]$actionCode)
    switch ($actionCode) {
        0 { return "Clean" }
        1 { return "Quarantine" }
        2 { return "Remove" }
        6 { return "Allow" }
        8 { return "UserDefined" }
        9 { return "NoAction" }
        default { return "Unknown ($actionCode)" }
    }
}

# Function Change-DefenderFolderOwnership
function Change-DefenderFolderOwnership {
    Show-FunctionHeader
    Write-Host "Defender Folder Ownership..."

    if (-not (Confirm-CompatOrBatch -HackName "FolderOwnership")) {
        return
    }

    $defenderPath = "C:\ProgramData\Microsoft\Windows Defender"

    if (-not (Test-Path $defenderPath)) {
        Write-Host "..Defender folder not found at expected path."
        Write-Host "..Path: $defenderPath"
        return
    }

    try {
        Write-Host "..Taking ownership (this may take a moment)..."
        & takeown /f "$defenderPath" /r /d y 2>&1 | Out-Null
        Write-Host "..Setting permissions..."
        & icacls "$defenderPath" /grant Administrators:F /t 2>&1 | Out-Null
        Write-Host "...Defender Folder Ownership Changed."
    }
    catch {
        $errorMessage = "Error in Change-DefenderFolderOwnership: $($_.Exception.Message)"
        Log-Error $errorMessage
        Write-Host $errorMessage
    }
}

# Function Disable-DefenderScheduledTasks
function Disable-DefenderScheduledTasks {
    Show-FunctionHeader
    Write-Host "Disable Defender Scheduled Tasks..."

    if (-not (Confirm-CompatOrBatch -HackName "ScheduledTasks")) {
        return
    }

    $tasks = Get-DefenderScheduledTasks -VersionInfo $Global:VersionInfo
    $successCount = 0
    $failCount = 0

    foreach ($taskName in $tasks) {
        try {
            Get-ScheduledTask $taskName -ErrorAction Stop | Disable-ScheduledTask | Out-Null
            Write-Host "..Disabled: $taskName"
            $successCount++
        }
        catch {
            $failCount++
            Write-Host "..Skipped: $taskName (not found or protected)"
            Log-Error "Task skip: $taskName - $($_.Exception.Message)"
        }
    }

    Write-Host ""
    if ($failCount -eq 0) {
        Write-Host "...Defender Scheduled Tasks Disabled."
    } else {
        Write-Host "...$successCount disabled, $failCount skipped."
    }
}

# Function Disable-DefenderServicesAndDrivers
function Disable-DefenderServicesAndDrivers {
    Show-FunctionHeader
    Write-Host "Disable Defender Services and Drivers..."

    if (-not (Confirm-CompatOrBatch -HackName "Services")) {
        return
    }

    $lists = Get-DefenderServiceList -VersionInfo $Global:VersionInfo
    $successCount = 0
    $failCount = 0

    foreach ($svc in $lists.Services) {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$svc"
        if (Test-Path $regPath) {
            Write-Host "..Disabling Service: $svc"
            try {
                Set-ItemProperty -Path $regPath -Name Start -Value 4 -ErrorAction Stop
                Write-Host "  Set Start=4"
                $successCount++
            }
            catch {
                $failCount++
                Write-Host "  Failed (protected or access denied)"
                Log-Error "Service: $svc - $($_.Exception.Message)"
            }
        } else {
            Write-Host "..Skipped: $svc (not present on this system)"
        }
    }

    foreach ($drv in $lists.Drivers) {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$drv"
        if (Test-Path $regPath) {
            Write-Host "..Disabling Driver: $drv"
            try {
                Set-ItemProperty -Path $regPath -Name Start -Value 4 -ErrorAction Stop
                Write-Host "  Set Start=4"
                $successCount++
            }
            catch {
                $failCount++
                Write-Host "  Failed (protected or access denied)"
                Log-Error "Driver: $drv - $($_.Exception.Message)"
            }
        } else {
            Write-Host "..Skipped: $drv (not present on this system)"
        }
    }

    Write-Host ""
    if ($failCount -eq 0) {
        Write-Host "...Defender Services and Drivers Disabled."
    } else {
        Write-Host "...$successCount disabled, $failCount failed."
    }
}

# ============================================================
#  PROCESS TERMINATION
# ============================================================

# Function Run-ProcessScans
function Run-ProcessScans {
    Show-FunctionHeader
    Write-Host "Process Scans & Terminate..."

    if (-not (Confirm-CompatOrBatch -HackName "ProcessTermination")) {
        return
    }

    Write-Host "Finding & Closing, Processes..."
    $Global:ScanPassCounter = 0
    try {
        1..2 | ForEach-Object { ValidateAndExecute }
    }
    catch {
        Log-Error $_.Exception.Message
        Start-Sleep -Seconds 1
    }
    Write-Host "...2 Passes Complete."
    Start-Sleep -Seconds 1
}

# Function Stop-TargetProcesses
function Stop-TargetProcesses {
    try {
        $patterns = Get-DefenderProcessPatterns -VersionInfo $Global:VersionInfo
        $targets = Get-Process | Where-Object {
            $name = $_.ProcessName
            $match = $false
            foreach ($p in $patterns) {
                if ($name -like $p) { $match = $true; break }
            }
            $match
        }
        Write-Host "Found $($targets.Count) processes"
        foreach ($proc in $targets) {
            Write-Host "Terminating $($proc.Id) $($proc.ProcessName)"
            try {
                $proc | Stop-Process -Force -ErrorAction Stop
                Write-Host "Stopped $($proc.Id) $($proc.ProcessName)"
            }
            catch {
                Write-Host "Error $($proc.Id) $($proc.ProcessName)"
            }
        }
    }
    catch {
        Log-Error $_.Exception.Message
        Write-Host "Error in process termination: $($_.Exception.Message)"
    }
}

# Function ValidateAndExecute
function ValidateAndExecute {
    $Global:ScanPassCounter++
    Write-Host "Starting Pass $($Global:ScanPassCounter)..."
    Write-Host "Pass $($Global:ScanPassCounter) In 5 Seconds.."
    Start-Sleep -Seconds 5
    Stop-TargetProcesses
}

# ============================================================
#  SATAN INSIDE FUNCTIONS (merged from DisableSatanInside-10)
# ============================================================

# Function Show-SatanServiceList
function Show-SatanServiceList {
    $services = Get-SatanServiceList -VersionInfo $Global:VersionInfo
    Write-Host "  Affected Services ($($Global:VersionInfo.DisplayVersion)):"
    foreach ($svc in $services) {
        Write-Host "  - $($svc.Display)"
    }
}

# Function Disable-SatanServices
function Disable-SatanServices {
    Show-FunctionHeader
    Write-Host "Disabling AD-Related Services..."
    Write-Host "OS: $($Global:VersionInfo.DisplayVersion)"
    Write-Host ""

    $services = Get-SatanServiceList -VersionInfo $Global:VersionInfo
    $successCount = 0
    $failCount = 0

    foreach ($svc in $services) {
        Write-Host "Processing service: $($svc.Name)"
        try {
            # Check if service exists first
            $svcObj = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
            if ($null -eq $svcObj) {
                Write-Host "..Skipped: $($svc.Name) (not present)"
                $failCount++
                continue
            }
            Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction Stop
            Write-Host "..Service $($svc.Name) disabled."
            $successCount++
        }
        catch {
            $failCount++
            Log-Error "Satan: $($svc.Name) - $($_.Exception.Message)"
            Write-Host "..Failed: $($svc.Name)"
        }
        Start-Sleep -Milliseconds 500
    }

    Write-Host ""
    Write-Host "...$successCount disabled, $failCount failed/skipped."
    Write-Host "Please restart your computer after exiting."
}

# Function Enable-SatanServices
function Enable-SatanServices {
    Show-FunctionHeader
    Write-Host "Enabling AD-Related Services..."
    Write-Host "OS: $($Global:VersionInfo.DisplayVersion)"
    Write-Host ""

    $services = Get-SatanServiceList -VersionInfo $Global:VersionInfo
    $successCount = 0
    $failCount = 0

    foreach ($svc in $services) {
        Write-Host "Processing service: $($svc.Name)"
        try {
            $svcObj = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
            if ($null -eq $svcObj) {
                Write-Host "..Skipped: $($svc.Name) (not present)"
                $failCount++
                continue
            }
            Set-Service -Name $svc.Name -StartupType Automatic -ErrorAction Stop
            Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
            Write-Host "..Service $($svc.Name) enabled."
            $successCount++
        }
        catch {
            $failCount++
            Log-Error "Satan enable: $($svc.Name) - $($_.Exception.Message)"
            Write-Host "..Failed: $($svc.Name)"
        }
        Start-Sleep -Milliseconds 500
    }

    Write-Host ""
    Write-Host "...$successCount enabled, $failCount failed/skipped."
    Write-Host "Please restart your computer after exiting."
}

# ============================================================
#  RESTORE DEFAULT FUNCTIONS
# ============================================================

# Function Restore-DefenderRegistry
# Removes all policy registry keys that were set by option 2.
function Restore-DefenderRegistry {
    Show-FunctionHeader
    Write-Host "Restoring Defender Registry to defaults..."

    $entries = Get-DefenderRegistryCleanup -VersionInfo $Global:VersionInfo
    $successCount = 0
    $failCount = 0

    foreach ($entry in $entries) {
        Write-Host "..Removing: $($entry.Name)"
        try {
            if (Test-Path $entry.Path) {
                $existing = Get-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
                if ($null -ne $existing) {
                    Remove-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction Stop
                    Write-Host "..Removed: $($entry.Name)"
                    $successCount++
                } else {
                    Write-Host "..Already absent: $($entry.Name)"
                }
            } else {
                Write-Host "..Path not present: $($entry.Path)"
            }
        }
        catch {
            $failCount++
            Log-Error "Restore registry: $($entry.Name) - $($_.Exception.Message)"
            Write-Host "..Failed: $($entry.Name) (may be tamper-protected)"
        }
    }

    Write-Host ""
    Write-Host "...$successCount removed, $failCount failed."
}

# Function Restore-DefenderServices
# Sets Defender services and drivers back to their default startup types.
function Restore-DefenderServices {
    Show-FunctionHeader
    Write-Host "Restoring Defender Services to defaults..."

    $lists = Get-DefenderServiceList -VersionInfo $Global:VersionInfo
    $successCount = 0
    $failCount = 0

    # Services — default is Automatic (Start=2)
    foreach ($svcName in $lists.Services) {
        Write-Host "..Restoring service: $svcName"
        try {
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$svcName"
            if (Test-Path $regPath) {
                Set-ItemProperty -Path $regPath -Name "Start" -Value 2 -Type DWord -ErrorAction Stop
                $check = (Get-ItemProperty -Path $regPath -Name "Start" -ErrorAction SilentlyContinue).Start
                if ($check -eq 2) {
                    Write-Host "..Restored: $svcName (Start=2 Automatic)"
                    $successCount++
                } else {
                    Write-Host "..Warning: $svcName value not confirmed"
                    $failCount++
                }
            } else {
                Write-Host "..Skipped: $svcName (not present)"
            }
        }
        catch {
            $failCount++
            Log-Error "Restore service: $svcName - $($_.Exception.Message)"
            Write-Host "..Failed: $svcName (may need safe mode)"
        }
    }

    # Drivers — default is Boot Start (Start=0) for wdboot, System (Start=1) for others
    foreach ($drvName in $lists.Drivers) {
        Write-Host "..Restoring driver: $drvName"
        $defaultStart = if ($drvName -eq "wdboot") { 0 } else { 1 }
        try {
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$drvName"
            if (Test-Path $regPath) {
                Set-ItemProperty -Path $regPath -Name "Start" -Value $defaultStart -Type DWord -ErrorAction Stop
                Write-Host "..Restored: $drvName (Start=$defaultStart)"
                $successCount++
            } else {
                Write-Host "..Skipped: $drvName (not present)"
            }
        }
        catch {
            $failCount++
            Log-Error "Restore driver: $drvName - $($_.Exception.Message)"
            Write-Host "..Failed: $drvName (may need safe mode)"
        }
    }

    Write-Host ""
    Write-Host "...$successCount restored, $failCount failed."
}

# Function Restore-DefenderScheduledTasks
# Re-enables Defender scheduled tasks.
function Restore-DefenderScheduledTasks {
    Show-FunctionHeader
    Write-Host "Restoring Defender Scheduled Tasks..."

    $tasks = Get-DefenderScheduledTasks -VersionInfo $Global:VersionInfo
    $taskPath = "\Microsoft\Windows\Windows Defender\"
    $successCount = 0
    $failCount = 0

    foreach ($taskName in $tasks) {
        Write-Host "..Enabling: $taskName"
        try {
            $task = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue
            if ($null -eq $task) {
                Write-Host "..Skipped: $taskName (not found)"
                continue
            }
            Enable-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop | Out-Null
            Write-Host "..Enabled: $taskName"
            $successCount++
        }
        catch {
            $failCount++
            Log-Error "Restore task: $taskName - $($_.Exception.Message)"
            Write-Host "..Failed: $taskName"
        }
    }

    Write-Host ""
    Write-Host "...$successCount enabled, $failCount failed."
}