# AntiMsVirus10-11

### STATUS: WORKING
- This program is able to disable the Microsoft Anti-Virus and non-productive AD-related services in Windows 10 and 11. It was originally two separate programs (AntiMsVirus and DisableSatanInside) now merged into one. Safe Mode is recommended for best results; the program detects your boot mode and Defender platform version at startup, and warns you per-operation what will and won't work. It is COMPLETE OVERKILL and does the task 10 times over, though thats nice too B).

## DESCRIPTION
Microsoft Anti-Malware in Windows 10 onwards is turned off by manually going into Ms AV settings, but the user must do this EVERY TIME they boot up, and even then, there are relating processes still present, and the service is not able to be disabled in services. AntiMsVirus is a tool to shut down and close the Microsoft Anti-Malware in Windows 10 and 11. It targets Defender processes ("Mp*", "MsMp*", "MpDefenderCoreService"), registry policies, services, drivers, scheduled tasks, and folder permissions. It also disables non-productive AD-related Windows services (Netlogon, Remote Desktop, Remote Registry, Windows Update, SSDP Discovery, etc.) that were previously handled by the separate DisableSatanInside program. The program detects your exact Windows build and Defender platform version at runtime, and adjusts its operations and compatibility warnings accordingly — for example, the DisableAntiSpyware registry key is only applied on early Win10 platforms where it still works, and MDCoreSvc is only targeted when the Defender platform is new enough to have it. The reason you would want to do such things, is because some people believe its better to have passive protection ran once a month as a, scheduled or manual, task, when other maintenance is also done; in short, having something continually run to check for virus, defeats the point of an anti-virus in its classic sense.

### FEATURES
- **User Interface**: A menu-driven interface for easy interaction and selection of different features, with batch execution (Enable Hacks runs all 7 options sequentially) and a Restore Default option to undo changes.
- **Version-Aware Compatibility**: Detects Windows build, Defender platform version, and boot mode at startup. Each operation shows a compatibility status (WORKS / SAFEMODE / LIMITED / INEFFECTIVE) with a note before prompting, so you know what to expect.
- **Registry Modification**: Functions to modify Defender policy registry keys including Real-Time Protection, behavior monitoring, and on-access protection. DisableAntiSpyware is only applied on early Defender platforms where it is still honoured.
- **Service & Driver Management**: Disables Defender services (WinDefend, WdNisSvc, Sense, MDCoreSvc) and drivers (WdNisDrv, wdfilter, wdboot) via registry Start values, with per-item error handling. MDCoreSvc conditionally targeted based on Defender platform version.
- **Process Management**: Identifies and terminates Defender processes in two passes with version-aware patterns including MpDefenderCoreService on modern platforms.
- **Tamper Protection Disabling**: Attempts to disable tamper protection via Set-MpPreference; warns that the Windows Security GUI toggle is more reliable on modern platforms.
- **Customizable Defender Settings**: Disables real-time monitoring and sets threat response actions (Low/Moderate/High) to Allow via Set-MpPreference.
- **Scheduled Task Management**: Disables Defender scheduled tasks (Cache Maintenance, Cleanup, Scheduled Scan, Verification) with per-task error handling.
- **Folder Ownership Modification**: Changes ownership of the Windows Defender directory via takeown and icacls.
- **Satan Inside (AD Services)**: Disables non-productive AD-related services: Netlogon, Windows Time, Remote Desktop Configuration, Remote Desktop Services, Remote Registry, IP Helper, SSDP Discovery, Function Discovery Provider Host, Function Discovery Resource Publication, Windows Error Reporting, Diagnostic Policy Service, and Windows Update.
- **Restore Default**: Reverses all changes — removes registry policy keys, restores Defender services/drivers to default startup types, re-enables scheduled tasks, and re-enables AD-related services.
- **Visual Elements**: Incorporates ASCII art for a more engaging user experience.

### PREVIEW
- Its no small task to remove a virus (v1.02)...
```
               _    __  ____     __
              / \  |  \/  \ \   / /
       _____ / _ \_| |\/| |\ \_/ /____
      |_____/ ___ \| |__| |_\ V /_____|
           /_/   \_\_|  |_|  \_/
===============( AntiMsVirus )===============

    1. Disable Tamper Protection

    2. Registry Edits (requires restart)

    3. Disable Services (requires restart)

    4. Defender Folder Ownership

    5. Disable Defender Scheduled Tasks

    6. Run Process Scans & Terminate

    7. Disable Defender Features

Select, Menu Options=1-7, Exit Program=X:

```
- And here we see it in operation (v1.02)...
```
Disabling Tamper Protection...
Error: Operation failed with the following error: 0x%1!x!
..Skipping State Check

Disabling Defender Features...
..Disabling Low-Threats..
..Disabling Moderate-Threats..
..Disabling High-Threats..
..Disabling Realtime-Monitoring..
...Defender Features Disabled.

Check Features States...
..Low Threats: Allow
..Moderate Threats: Allow
..High Threats: Allow
..Realtime Monitoring: True
...Features States Reported.

Finding & Closing, Processes...
Starting Pass 1...
Pass 1 In 5 Seconds..
Found 2 processes
Terminating 8264 MpCopyAccelerator
Error 8264 MpCopyAccelerator
Terminating 4872 MsMpEng
Error 4872 MsMpEng
Starting Pass 2...
Pass 2 In 5 Seconds..
Found 2 processes
Terminating 8264 MpCopyAccelerator
Error 8264 MpCopyAccelerator
Terminating 4872 MsMpEng
Error 4872 MsMpEng
...2 Passes Complete.
```

## REQUIREMENTS
- Windows 10 or Windows 11 (any build).
- Windows Powershell 5.1 or Powershell 7+.
- Administrator privileges.

### USAGE
Its never been easier to break your Operating System, here lemme explain the procedure...
- Ensure you have already tried programs such as, `DoNotSpy` and `0&0 Shut Up` and `Windows Privacy Tweaker` and `xp-AntiSpy`, first; these programs, may cover the issue you have.
1. Create a restore point, this may be useful later if experiencing issues, so you can revert changes.
2. Boot into Safe Mode for best results — type "safe mode" into the start menu. The program works in normal mode for some operations but will warn you where safe mode is needed.
3. Run the batch `AntiMsVirus.Bat` with Admin rights.
4. Try individual options (1-7) to see their compatibility with your system, or press E to Enable Hacks which runs all 7 in sequence plus disables AD services.
5. Press R for Restore Default if you need to undo changes.
6. Restart your computer after running.
7. Utilize your choice of Security software on the computer, I advise passive protection ran monthly.

### NOTATION
- Programs such as, `DoNotSpy` and `0&0 Shut Up` and `Windows Privacy Tweaker` and `xp-AntiSpy`, are better quality, but will not achive same things, this is why I ended up making AntiMsVirus.
- This is a program you probably want to use AFTER, you have setup all the stuff known to be sentitive, such as installing, WSL2 or things requiring MS Store, definately do that FIRST.
- DisableSatanInside-10 has been merged into this program and is no longer a separate project.
- You should also know and understand ALL of the things that this program is capable of disabling/breadking, as there will be consequences later. You may NOT want to enable all the hacks.

### DISCLAIMER
- You should not use this program unless you do not mind breaking the relating services, however there is the possibility the Restore Default option (R) will undo changes later, but I will not be testing the undo!!! You have been warned, if that part doesnt work, its because the disabling it part probably did do its job. 
- If the undo does not work, then there likely is no program to fix what this program breaks, other than reinstalling the OS, or some kind of system restore but restore may not work to cover all the files. This program modifies core windows configurations. 
- If you cannot reinstall your own OS/apps, then you should NOT be using this program, its strictly for Geeks whom like to take a risk for a little bit of, freedom and piece of mind, to have those processes, that so called "paranoid" people, do go on about, to be disabled/deleted, by any means necessary.
