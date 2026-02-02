# Script: scripts\platform.ps1

# Function Get-WindowsVersionInfo
function Get-WindowsVersionInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    $build = [int]$os.BuildNumber
    $caption = $os.Caption

    # Revision number from UBR (Update Build Revision) e.g. 19045.6809
    $ubr = 0
    try {
        $ubr = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name UBR -ErrorAction SilentlyContinue).UBR
        if ($null -eq $ubr) { $ubr = 0 }
    } catch { $ubr = 0 }

    $displayVersion = switch ($true) {
        ($build -ge 26100) { "Win11-24H2" }
        ($build -ge 22631) { "Win11-23H2" }
        ($build -ge 22621) { "Win11-22H2" }
        ($build -ge 22000) { "Win11-21H2" }
        ($build -ge 19045) { "Win10-22H2" }
        ($build -ge 19044) { "Win10-21H2" }
        ($build -ge 19043) { "Win10-21H1" }
        ($build -ge 19042) { "Win10-20H2" }
        ($build -ge 19041) { "Win10-2004" }
        ($build -ge 18363) { "Win10-1909" }
        ($build -ge 18362) { "Win10-1903" }
        default            { "Unknown-$build" }
    }

    # Full build string e.g. "19045.6809"
    $fullBuild = "$build"
    if ($ubr -gt 0) { $fullBuild = "$build.$ubr" }

    $osMajor = if ($build -ge 22000) { 11 } else { 10 }

    # Detect Safe Mode
    $safeMode = $false
    try {
        $bootOption = (Get-CimInstance Win32_ComputerSystem).BootupState
        if ($bootOption -match "Safe") { $safeMode = $true }
    } catch {}

    # Detect Defender platform version
    # This determines which features are available. Key boundary:
    #   4.18.2007.8 (Aug 2020) — DisableAntiSpyware deprecated
    #   4.18.23110.x (Nov 2023) — MDCoreSvc introduced
    $defenderPlatform = $null
    $defenderPlatformMajor = 0
    try {
        $mpStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($mpStatus -and $mpStatus.AMProductVersion) {
            $defenderPlatform = $mpStatus.AMProductVersion
            # Parse e.g. "4.18.2007.8" — we use the third segment for comparison
            $segments = $defenderPlatform.Split(".")
            if ($segments.Count -ge 3) {
                $defenderPlatformMajor = [int]$segments[2]
            }
        }
    } catch {}

    # Win10 sub-classification based on Defender platform:
    #   "Early"  — platform < 2007 (pre Aug 2020). DisableAntiSpyware works.
    #              Tamper protection exists but less aggressive.
    #   "Modern" — platform >= 2007 (post Aug 2020, includes all patched 22H2).
    #              DisableAntiSpyware deprecated/ignored.
    #              MDCoreSvc present if platform >= 23110.
    $win10Tier = "Modern"
    if ($osMajor -eq 10 -and $defenderPlatformMajor -gt 0 -and $defenderPlatformMajor -lt 2007) {
        $win10Tier = "Early"
    }

    # MDCoreSvc expected if platform >= 23110 (Nov 2023+)
    $hasMDCoreSvc = ($defenderPlatformMajor -ge 23110)

    return @{
        Build                = $build
        UBR                  = $ubr
        FullBuild            = $fullBuild
        DisplayVersion       = $displayVersion
        OsMajor              = $osMajor
        Caption              = $caption
        SafeMode             = $safeMode
        DefenderPlatform     = $defenderPlatform
        DefenderPlatformMajor = $defenderPlatformMajor
        Win10Tier            = $win10Tier
        HasMDCoreSvc         = $hasMDCoreSvc
    }
}

# ============================================================
#  COMPATIBILITY DATA
# ============================================================
#
# Status values:
#   "works"       - confirmed working
#   "safemode"    - works only from safe mode
#   "limited"     - runs but may be reverted by tamper protection
#   "ineffective" - OS ignores or actively reverts this change
#
# Win10 Early (platform < 4.18.2007.8, pre Aug 2020):
#   Rare now — only machines that haven't received Defender platform
#   updates since 2020. DisableAntiSpyware still works. Tamper
#   protection exists but less strict. No MDCoreSvc.
#
# Win10 Modern (platform >= 4.18.2007.8):
#   Includes all patched 22H2 builds (19045.2311 through 19045.6812+).
#   DisableAntiSpyware deprecated — key is ignored on consumer editions.
#   Tamper protection on by default, guards registry and services.
#   MDCoreSvc present on platform >= 4.18.23110 (Nov 2023+).
#   Safe mode required for service/driver/process changes.
#   RT Protection policy keys still applied as best-effort.
#   22H2 machines on ESU (post Oct 2025) behave identically.
#
# Win11 (21H2-24H2+):
#   DisableAntiSpyware: ignored, actively deleted by tamper protection.
#   Service Start=4: works from safe mode on most builds.
#   MDCoreSvc: present on all Win11 with current platform.
#   Kernel-level PPL protects processes even more aggressively.

# Function Get-HackCompatibility
function Get-HackCompatibility {
    param([hashtable]$VersionInfo)

    $tier = $VersionInfo.Win10Tier  # "Early" or "Modern"

    # Build Win10 notes with sub-version context
    $regWin10Note = if ($tier -eq "Early") {
        "Early platform — DisableAntiSpyware still honoured. RT Protection keys also applied."
    } else {
        "Modern platform — DisableAntiSpyware deprecated (skipped). RT Protection keys applied as best-effort."
    }
    $regWin10Status = if ($tier -eq "Early") { "safemode" } else { "limited" }

    $tamperWin10Note = if ($tier -eq "Early") {
        "Tamper protection less aggressive. Set-MpPreference more likely to succeed. Manual GUI toggle recommended."
    } else {
        "Must turn off via Windows Security GUI first. PowerShell alone usually fails."
    }

    $svcWin10Note = if ($tier -eq "Early") {
        "Service Start=4 may work even in normal mode. Safe mode recommended for reliability."
    } else {
        "Tamper protection guards services. Setting Start=4 requires safe mode."
    }

    $procWin10Note = if ($tier -eq "Early") {
        "Protected Process Light (PPL) active. Safe mode allows termination."
    } else {
        "PPL enforced. Safe mode required. Includes MpDefenderCoreService on platform 23110+."
    }

    $featWin10Note = if ($tier -eq "Early") {
        "Set-MpPreference more likely to succeed. Tamper protection less aggressive."
    } else {
        "Requires tamper protection off first. Some settings may revert on reboot."
    }

    return @{
        TamperProtection = @{
            Win10 = @{ Status = "limited";      Note = $tamperWin10Note }
            Win11 = @{ Status = "limited";      Note = "Must be turned off via Windows Security GUI first. PowerShell alone usually fails." }
        }
        Registry = @{
            Win10 = @{ Status = $regWin10Status; Note = $regWin10Note }
            Win11 = @{ Status = "ineffective";  Note = "DisableAntiSpyware is ignored and actively removed. RT Protection keys applied as best-effort." }
        }
        Services = @{
            Win10 = @{ Status = "safemode";     Note = $svcWin10Note }
            Win11 = @{ Status = "safemode";     Note = "Setting Start=4 works from safe mode through 24H2. May be reverted by major updates." }
        }
        FolderOwnership = @{
            Win10 = @{ Status = "works";        Note = "Works from safe mode or normal mode with admin." }
            Win11 = @{ Status = "safemode";     Note = "Recommended from safe mode. May break Defender definition updates via Windows Update." }
        }
        ScheduledTasks = @{
            Win10 = @{ Status = "works";        Note = "Tasks can be disabled with admin privileges." }
            Win11 = @{ Status = "works";        Note = "Tasks can be disabled with admin privileges." }
        }
        ProcessTermination = @{
            Win10 = @{ Status = "safemode";     Note = $procWin10Note }
            Win11 = @{ Status = "safemode";     Note = "Kernel-protected processes. Safe mode required." }
        }
        DefenderFeatures = @{
            Win10 = @{ Status = "limited";      Note = $featWin10Note }
            Win11 = @{ Status = "limited";      Note = "Works if tamper protection is off. Some settings may revert on reboot." }
        }
        SatanServices = @{
            Win10 = @{ Status = "works";        Note = "Standard Windows services. Can be disabled with admin." }
            Win11 = @{ Status = "works";        Note = "Same services exist on Win11. Can be disabled with admin." }
        }
    }
}

# Function Show-CompatWarning
# Displays compatibility info and asks user to proceed.
# Returns $true to proceed, $false to skip.
function Show-CompatWarning {
    param(
        [string]$HackName,
        [hashtable]$VersionInfo
    )
    $compat = Get-HackCompatibility -VersionInfo $VersionInfo
    $osKey = if ($VersionInfo.OsMajor -ge 11) { "Win11" } else { "Win10" }

    if (-not $compat.ContainsKey($HackName)) {
        return $true
    }

    $info = $compat[$HackName][$osKey]
    $status = $info.Status

    $color = switch ($status) {
        "works"       { "Green" }
        "safemode"    { "Yellow" }
        "limited"     { "Yellow" }
        "ineffective" { "Red" }
        default       { "Gray" }
    }

    Write-Host ""
    # Show build + tier on Win10 for clarity
    $tierLabel = ""
    if ($VersionInfo.OsMajor -eq 10) {
        $tierLabel = " ($($VersionInfo.Win10Tier))"
    }
    Write-Host "  [$($VersionInfo.DisplayVersion) $($VersionInfo.FullBuild)$tierLabel] " -NoNewline
    Write-Host "$($status.ToUpper())" -ForegroundColor $color
    Write-Host "  $($info.Note)" -ForegroundColor Gray

    if ($status -eq "safemode" -and -not $VersionInfo.SafeMode) {
        Write-Host "  WARNING: Best results require Safe Mode. You are NOT in Safe Mode." -ForegroundColor Red
    }

    # Win11 or Win10 Modern registry — DisableAntiSpyware skipped
    if ($HackName -eq "Registry") {
        if ($VersionInfo.OsMajor -ge 11) {
            Write-Host "  Main registry key (DisableAntiSpyware) will be skipped on Win11." -ForegroundColor Red
            Write-Host "  RT Protection keys will still be applied as best-effort." -ForegroundColor Yellow
        } elseif ($VersionInfo.Win10Tier -eq "Modern") {
            Write-Host "  DisableAntiSpyware deprecated on modern platforms — will be skipped." -ForegroundColor Red
            Write-Host "  RT Protection keys will still be applied as best-effort." -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host -NoNewline "  Proceed? (Y/N): "
    $confirm = Read-Host
    return ($confirm.ToUpper() -eq 'Y')
}

# ============================================================
#  SERVICE / DRIVER / REGISTRY LISTS
# ============================================================

# Function Get-SatanServiceList
function Get-SatanServiceList {
    param([hashtable]$VersionInfo)

    return @(
        @{ Name = "Netlogon";       Display = "Netlogon" }
        @{ Name = "W32Time";        Display = "Windows Time" }
        @{ Name = "SessionEnv";     Display = "Remote Desktop Configuration" }
        @{ Name = "TermService";    Display = "Remote Desktop Services" }
        @{ Name = "RemoteRegistry"; Display = "Remote Registry" }
        @{ Name = "iphlpsvc";       Display = "IP Helper" }
        @{ Name = "SSDPSRV";       Display = "SSDP Discovery" }
        @{ Name = "fdPHost";       Display = "Function Discovery Provider Host" }
        @{ Name = "FDResPub";      Display = "Function Discovery Resource Publication" }
        @{ Name = "WerSvc";        Display = "Windows Error Reporting Service" }
        @{ Name = "DPS";           Display = "Diagnostic Policy Service" }
        @{ Name = "wuauserv";      Display = "Windows Update" }
    )
}

# Function Get-DefenderServiceList
# MDCoreSvc included when Defender platform >= 4.18.23110 (Nov 2023).
# Present on Win10 22H2 with current platform updates and all Win11.
# Per-item error handling in utility.ps1 skips it if not present.
function Get-DefenderServiceList {
    param([hashtable]$VersionInfo)

    $services = @("WdNisSvc", "WinDefend", "Sense")
    if ($VersionInfo.HasMDCoreSvc) {
        $services += "MDCoreSvc"
    }
    $drivers = @("WdNisDrv", "wdfilter", "wdboot")

    return @{
        Services = $services
        Drivers  = $drivers
    }
}

# Function Get-DefenderScheduledTasks
function Get-DefenderScheduledTasks {
    param([hashtable]$VersionInfo)

    return @(
        "Windows Defender Cache Maintenance"
        "Windows Defender Cleanup"
        "Windows Defender Scheduled Scan"
        "Windows Defender Verification"
    )
}

# Function Get-DefenderRegistryEntries
# Returns registry modifications for disabling Defender.
# DisableAntiSpyware applied on Win10 Early only.
# Win10 Modern and Win11: key is deprecated/ignored, skipped.
# RT Protection keys applied on all as best-effort.
function Get-DefenderRegistryEntries {
    param([hashtable]$VersionInfo)

    $entries = @()
    $defPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    $rtpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"

    # DisableAntiSpyware — Win10 Early only (pre platform 4.18.2007.8)
    if ($VersionInfo.OsMajor -le 10 -and $VersionInfo.Win10Tier -eq "Early") {
        $entries += @{
            Path  = $defPath
            Name  = "DisableAntiSpyware"
            Value = 1
            Note  = "Early platform — key still honoured"
        }
    }

    # Real-Time Protection keys — all versions, best-effort
    $entries += @(
        @{ Path = $rtpPath; Name = "DisableBehaviorMonitoring";    Value = 1; Note = "Disable behavior monitoring" }
        @{ Path = $rtpPath; Name = "DisableOnAccessProtection";    Value = 1; Note = "Disable on-access file protection" }
        @{ Path = $rtpPath; Name = "DisableScanOnRealtimeEnable";  Value = 1; Note = "Disable scan on RT enable" }
        @{ Path = $rtpPath; Name = "DisableRealtimeMonitoring";    Value = 1; Note = "Disable realtime monitoring" }
    )

    # Additional policy keys — all versions
    $entries += @(
        @{ Path = $defPath; Name = "DisableAntiVirus";            Value = 1; Note = "Disable antivirus component" }
        @{ Path = $defPath; Name = "DisableRoutinelyTakingAction"; Value = 1; Note = "Disable automatic threat actions" }
        @{ Path = $defPath; Name = "ServiceKeepAlive";            Value = 0; Note = "Disable service keep-alive" }
    )

    return $entries
}

# Function Get-DefenderRegistryCleanup
# Returns the registry paths/names to DELETE when restoring defaults.
function Get-DefenderRegistryCleanup {
    param([hashtable]$VersionInfo)

    $defPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    $rtpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"

    return @(
        @{ Path = $defPath; Name = "DisableAntiSpyware" }
        @{ Path = $defPath; Name = "DisableAntiVirus" }
        @{ Path = $defPath; Name = "DisableRoutinelyTakingAction" }
        @{ Path = $defPath; Name = "ServiceKeepAlive" }
        @{ Path = $rtpPath; Name = "DisableBehaviorMonitoring" }
        @{ Path = $rtpPath; Name = "DisableOnAccessProtection" }
        @{ Path = $rtpPath; Name = "DisableScanOnRealtimeEnable" }
        @{ Path = $rtpPath; Name = "DisableRealtimeMonitoring" }
    )
}

# Function Get-DefenderProcessPatterns
function Get-DefenderProcessPatterns {
    param([hashtable]$VersionInfo)
    $patterns = @("Mp*", "MsMp*")
    if ($VersionInfo.HasMDCoreSvc) {
        $patterns += "MpDefenderCoreService"
    }
    return $patterns
}