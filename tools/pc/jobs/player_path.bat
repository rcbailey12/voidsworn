@echo off
rem Record both fresh Sunward routes from an installed Windows export.
rem Optional: game export folder, full recording folder, review output folder, one seed to retry.
setlocal EnableExtensions DisableDelayedExpansion
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\..\contrib\codex\player_path_1119\run.ps1" %*
set "RESULT=%ERRORLEVEL%"
if "%~1"=="" pause
exit /b %RESULT%
