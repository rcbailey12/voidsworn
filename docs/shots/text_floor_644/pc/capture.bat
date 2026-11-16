@echo off
rem Reproduce issue 671. Scratch files go to TEMP; pictures are named JPGs at 720 lines.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0capture.ps1" %*
exit /b %ERRORLEVEL%
