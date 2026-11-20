@echo off
rem Double-click. Windows asks once to run as administrator (some old folders were made by another account and only
rem an administrator can read them). It then lists the old folders on CLEAN_OLD_TEMP_1180_list.txt with sizes and
rem dates, and deletes exactly those only if you type YES. Anything else stops with nothing removed.
net session >nul 2>&1
if errorlevel 1 (
  powershell.exe -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b 0
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CLEAN_OLD_TEMP_1180.ps1"
pause
