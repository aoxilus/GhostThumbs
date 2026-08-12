@echo off
title GhostThumbs - Cloud Thumbnail Cacher
color 0D

echo.
echo   ======================================
echo    GhostThumbs v1.0.0
echo    See cloud files. Keep your space.
echo   ======================================
echo.
echo   This will scan your cloud storage folders
echo   (Dropbox, OneDrive, Google Drive) and cache
echo   thumbnails for all your cloud-only images.
echo.
echo   Your files stay in the cloud. Only the tiny
echo   thumbnail previews are kept locally.
echo.
echo   Press any key to start, or close this window to cancel.
pause >nul

echo.
echo   Starting GhostThumbs...
echo.

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0GhostThumbs.ps1" -AutoDetect -Recurse

echo.
echo   ======================================
echo    Done! You can close this window.
echo   ======================================
echo.
pause
