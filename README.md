# AntiMsVirus10-11

### STATUS: WORKING
- This program is able to disable the Microsoft Anti-Virus, however, due to development issues it was not tested in Safe Mode until later, it, is COMPLETE OVERKILL and does the task 10 times over, though thats nice too B).  

## DESCRIPTION
Microsoft Anti-Malware in Windows 10 onwards is turned off by manually going into Ms AV settings, but the user must do this EVERY TIME they boot up, and even then, there are relating processes still present, and the service is not able to be disabled in services. AntiMsVirus is a tool to, shut down and close, the Microsoft Anti-Malware, in Windows 10, it is focused on locating and terminating processes that are related to Microsoft's anti-malware services or applications ("Mp*.*" and "MsMp*.*"). The reason you would want to do such things, is because some people believe its better to have passive protection ran once a month as a, scheduled or manual, task, when other maintenance is also done; in short, having something continually run to check for virus, defeats the point of an anti-virus in its classic sense.

### FEATURES
- **User Interface**: A menu-driven interface for easy interaction and selection of different features.
- **Registry Modification**: Functions to modify the registry to disable Microsoft Defender and related services.
- **Process Management**: Capability to identify and terminate specific processes related to Microsoft's anti-malware services.
- **Tamper Protection Disabling**: Ability to disable the tamper protection feature, which often prevents changes to Microsoft Defender settings.
- **Customizable Defender Settings**: Allows users to customize the behavior of Microsoft Defender, such as disabling real-time monitoring and altering threat response actions.
- **Visual Elements**: Incorporates ASCII art for a more engaging user experience.
- **Scheduled Task Management**: Includes functionality to disable scheduled tasks related to Windows Defender, ensuring further minimization of its activities.
- **Folder Ownership Modification**: Provides a feature to change the ownership of the Windows Defender directory, facilitating more profound system-level changes for disabling the antivirus.

### PREVIEW
- Its no small task to remove a virus...
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
- And here we see it in operation...
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
- Windows 10/11
- Windows Powershell or Powershell Core.

### USAGE
* You should not use this program, unless you are NEVER EVER intending to use Microsoft Anti-Virus.
1. Create a restore point, this may be useful later if experiencing issues, so you can revert changes. 
2. On Windows 10v1903-11, you must first boot into Safe Mode, type "safe mode" into the start menu. 
3. When Safe Mode boots up, then you need to run the batch `AntiMsVirus.Bat` with Admin rights.
4. Try some of the options on the menu, then restart and see, or just go through them all in order.
5. Utilize your choice of Security software on the computer, I advise passive protection ran monthly.

### NOTATION
- After applying all the hacks in, normal and safe, modes, NO I did not break my computer or suffer any OS issues, so consider it safe, but again, if you are going to want to turn the MS Virus back on at some point, then don't use my program, as I will not be testing the back-on part.

## DEVELOPMENT
- Not really going to happen, but heres the potential plans... 
1. Merge Disable Satan Inside into AntiMsVirus10-11, like AntiMsVirus8-81 (will be if not done).
1. Options to delete the defender folder, after setting the defender folder permission (is this safe?).
2. Make sure all Outputted text is in correct formatting regarding, spaces and dots.
3. Consistency in error reporting, sometimes it prints to screen only, sometimes it uses the log too.

## DISCLAIMER
This software is subject to the terms in License.Txt, covering usage, distribution, and modifications. For full details on your rights and obligations, refer to License.Txt.
