# Script: main.ps1
. .\scripts\artwork.ps1
. .\scripts\platform.ps1
. .\scripts\utility.ps1

# Variables
$ErrorActionPreference = 'Stop'
$Global:ScanPassCounter = 0
$Global:BatchMode = $false

# Initialization
Set-Location -Path $PSScriptRoot
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Admin Required, Run As Admin!`n" -ForegroundColor Red
    exit
}

# Detect Windows Version
$Global:VersionInfo = Get-WindowsVersionInfo
$detectedOs = $Global:VersionInfo.DisplayVersion
$detectedBuild = $Global:VersionInfo.Build
$isSafeMode = $Global:VersionInfo.SafeMode

# Validate supported OS
if ($Global:VersionInfo.Build -lt 18362) {
    Write-Host "Unsupported OS (Build $detectedBuild). Requires Win10 1903+." -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit
}

Clear-Host
Write-Host "`n`nAntiMsVirus Started...."
Write-Host "Detected: $detectedOs (Build $detectedBuild)"
if ($Global:VersionInfo.DefenderPlatform) {
    Write-Host "Defender Platform: $($Global:VersionInfo.DefenderPlatform)"
}
if ($isSafeMode) {
    Write-Host "Mode: SAFE MODE" -ForegroundColor Green
} else {
    Write-Host "Mode: Normal Boot" -ForegroundColor Yellow
}
Write-Host ""
Start-Sleep -Seconds 2

# Function Log-Error
function Log-Error {
    param($ErrorMessage)
    $logFilePath = ".\Error-Crash.Log"
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$timestamp] $ErrorMessage" | Out-File -Append -FilePath $logFilePath
    }
    catch {
        Write-Host "Error-Crash.Log Protected!"
        Write-Host "Run As Admin/Close Notepad!"
    }
}

# Function Show-Menu
function Show-Menu {
    while ($true) {
        Clear-Host
        $divider = "=" * 79
        Write-Host $divider
        Write-Host "    Anti-MsVirus 10-11: Main Menu"
        Write-Host $divider
        Write-Host ""
        Write-Host ""
        Write-Host "    1. Disable Tamper Protection     [compat check -> confirm -> execute]"
        Write-Host ""
        Write-Host "    2. Registry Edits                [compat check -> confirm -> per-key with verify]"
        Write-Host ""
        Write-Host "    3. Disable Services & Drivers    [compat check -> confirm -> per-item + MDCoreSvc]"
        Write-Host ""
        Write-Host "    4. Defender Folder Ownership     [compat check -> confirm -> takeown + icacls]"
        Write-Host ""
        Write-Host "    5. Disable Scheduled Tasks       [compat check -> confirm -> per-task]"
        Write-Host ""
        Write-Host "    6. Process Scans & Terminate     [compat check -> confirm -> 2 passes]"
        Write-Host ""
        Write-Host "    7. Disable Defender Features     [compat check -> confirm -> Set-MpPreference]"
        Write-Host ""
        Write-Host ""
        Write-Host $divider
        Write-Host -NoNewline "Selection; Options = 1-7, Enable Hacks = E, Restore Default = R, Exit = X: "
        $input = Read-Host
        switch ($input.ToUpper()) {
            '1' {
                Run-DisableTamperProtection
                Start-Sleep -Seconds 5
            }
            '2' {
                Disable-DefenderRegistry
                Start-Sleep -Seconds 5
            }
            '3' {
                Disable-DefenderServicesAndDrivers
                Start-Sleep -Seconds 5
            }
            '4' {
                Change-DefenderFolderOwnership
                Start-Sleep -Seconds 5
            }
            '5' {
                Disable-DefenderScheduledTasks
                Start-Sleep -Seconds 5
            }
            '6' {
                Run-ProcessScans
                Start-Sleep -Seconds 5
            }
            '7' {
                Run-DisableDefenderFeatures
                Start-Sleep -Seconds 5
            }
            'E' {
                Run-EnableHacks
            }
            'R' {
                Run-RestoreDefault
            }
            'X' {
                Write-Host "Exiting..."
                Start-Sleep -Seconds 1
                return
            }
            default {
                Write-Host "Invalid choice, please try again."
                Start-Sleep -Seconds 2
            }
        }
    }
}

# Function Run-EnableHacks
# Runs all 7 Defender hacks in order, then disables Satan Inside services.
function Run-EnableHacks {
    Clear-Host
    Show-Header
    Write-Host "Enable Hacks Selected."
    Write-Host ""
    Write-Host "This will run options 1-7 in order, then disable"
    Write-Host "AD-related services (Satan Inside)."
    Write-Host ""
    Write-Host -NoNewline "Confirm Enable Hacks? (Y/N): "
    $confirm = Read-Host
    if ($confirm.ToUpper() -ne 'Y') { return }

    $Global:BatchMode = $true
    Write-Host ""
    Write-Host "Running 1. Disable Tamper Protection..."
    Run-DisableTamperProtection
    Start-Sleep -Seconds 2
    Write-Host ""

    Write-Host "Running 2. Registry Edits..."
    Disable-DefenderRegistry
    Start-Sleep -Seconds 2
    Write-Host ""

    Write-Host "Running 3. Disable Services & Drivers..."
    Disable-DefenderServicesAndDrivers
    Start-Sleep -Seconds 2
    Write-Host ""

    Write-Host "Running 4. Defender Folder Ownership..."
    Change-DefenderFolderOwnership
    Start-Sleep -Seconds 2
    Write-Host ""

    Write-Host "Running 5. Disable Scheduled Tasks..."
    Disable-DefenderScheduledTasks
    Start-Sleep -Seconds 2
    Write-Host ""

    Write-Host "Running 6. Process Scans & Terminate..."
    Run-ProcessScans
    Start-Sleep -Seconds 2
    Write-Host ""

    Write-Host "Running 7. Disable Defender Features..."
    Run-DisableDefenderFeatures
    Start-Sleep -Seconds 2
    Write-Host ""

    Write-Host "Running 8. Disable Satan Inside Services..."
    Disable-SatanServices
    Start-Sleep -Seconds 2
    Write-Host ""

    $Global:BatchMode = $false
    Write-Host "...Enable Hacks Complete."
    Write-Host "Please restart your computer."
    Start-Sleep -Seconds 5
}

# Function Run-RestoreDefault
# Reverses hacks: removes registry keys, re-enables services/drivers,
# re-enables scheduled tasks, re-enables Satan Inside services.
function Run-RestoreDefault {
    Clear-Host
    Show-Header
    Write-Host "Restore Default Selected."
    Write-Host ""
    Write-Host "This will undo registry edits, re-enable Defender"
    Write-Host "services/drivers, re-enable scheduled tasks, and"
    Write-Host "re-enable AD-related services (Satan Inside)."
    Write-Host ""
    Write-Host -NoNewline "Confirm Restore Default? (Y/N): "
    $confirm = Read-Host
    if ($confirm.ToUpper() -ne 'Y') { return }

    $Global:BatchMode = $true
    Write-Host ""

    Write-Host "Restoring 1. Registry keys..."
    Restore-DefenderRegistry
    Start-Sleep -Seconds 2
    Write-Host ""

    Write-Host "Restoring 2. Defender Services & Drivers..."
    Restore-DefenderServices
    Start-Sleep -Seconds 2
    Write-Host ""

    Write-Host "Restoring 3. Scheduled Tasks..."
    Restore-DefenderScheduledTasks
    Start-Sleep -Seconds 2
    Write-Host ""

    Write-Host "Restoring 4. Satan Inside Services..."
    Enable-SatanServices
    Start-Sleep -Seconds 2
    Write-Host ""

    $Global:BatchMode = $false
    Write-Host "...Restore Default Complete."
    Write-Host "Please restart your computer."
    Start-Sleep -Seconds 5
}

# Entry Point
Show-Menu
Write-Host "`n....AntiMsVirus Finished.`n"