@echo off
rem Issue 1180 oneoff2 probe: read-only report on the 10 stuck board copies and the idle helper folders.
rem Writes voidsworn_test\opus1180\oneoff2\probe_report.txt. Deletes nothing.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0PROBE_1180_ONEOFF2.ps1"
exit /b %ERRORLEVEL%
