@echo off
setlocal
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js is required. No checks ran.
  pause
  exit /b 2
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_checks.ps1" -Godot "%~1"
set "VOIDSWORN_FINAL_EXIT=%ERRORLEVEL%"
pause
exit /b %VOIDSWORN_FINAL_EXIT%
