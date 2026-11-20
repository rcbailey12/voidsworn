@echo off
rem Record both fresh Sunward routes from an installed Windows export.
rem Optional: game export folder, full recording folder, review output folder, one seed to retry.
setlocal EnableExtensions DisableDelayedExpansion
rem The recorder sets and checks its own fresh APPDATA before each engine start.
set "PC_REAL_PROFILE=1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\..\contrib\codex\player_path_1119\run.ps1" %*
set "RESULT=%ERRORLEVEL%"
if "%~1"=="" pause
exit /b %RESULT%
