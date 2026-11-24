@echo off
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0janitor.ps1" %*
exit /b %ERRORLEVEL%
