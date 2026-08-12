@echo off
title GhostThumbs - Install Scheduled Task
color 0E

echo.
echo   ======================================
echo    GhostThumbs - Scheduled Task Setup
echo   ======================================
echo.
echo   This will create a Windows Scheduled Task 
echo   that runs GhostThumbs automatically when 
echo   you log in, so your cloud file thumbnails
echo   are always up to date.
echo.
echo   Press any key to install, or close this window to cancel.
pause >nul

echo.
echo   Installing scheduled task...

set SCRIPT_PATH=%~dp0GhostThumbs.ps1

schtasks /create /tn "GhostThumbs" /tr "powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File \"%SCRIPT_PATH%\" -AutoDetect -Recurse -Silent" /sc onlogon /delay 0002:00 /rl limited /f

if %errorlevel%==0 (
    echo.
    echo   ✓ Scheduled task installed successfully!
    echo.
    echo   GhostThumbs will run 2 minutes after each login.
    echo   To remove: schtasks /delete /tn "GhostThumbs" /f
) else (
    echo.
    echo   ✗ Failed to install. Try running as Administrator.
)

echo.
pause
