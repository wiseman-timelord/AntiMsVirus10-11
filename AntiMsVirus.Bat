@echo off
REM mode 50,25
echo.
echo Batch Launcher Started....
echo.
echo.
timeout /t 1 /nobreak >nul

:: Initialization
echo Initialization Started...
echo Relocating To Script..
cd /d "%~dp0"
echo ...In Script Dir
echo Cleaning-Up Folder..
if exist "Error-Crash.Log" (
    del "Error-Crash.Log"
    echo ..Error-Crash deleted.
) else (
    echo ..No Error-Crash Present.
)
echo ...Initialization Completed.
echo.
timeout /t 1 /nobreak >nul

:: Launch Script
echo Starting Launch Sequence...
timeout /t 1 /nobreak >nul
echo Checking PowerShell..
where pwsh >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo ..Psc Detected.
    echo Launching Psc Script..
    timeout /t 1 /nobreak >nul
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File ".\main.ps1"
    echo ..Psc Process Exited.
) else (
    echo ..Ps Detected.
    echo Launching Ps Script..
    timeout /t 1 /nobreak >nul
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\main.ps1"
    echo ..Ps Process Exited.
)
echo ...Launch Sequence Complete.

timeout /t 1 /nobreak >nul

:: Exit
echo.
echo.
echo ....Batch Launcher Finished.
echo.
pause