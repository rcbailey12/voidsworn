@echo off
rem Free Windows proof for issue 687. Logs and tiny fixture repos stay in TEMP. No network or model calls.
rem Accounting faults exercise preservation commits and pushes only in local TEMP fixtures.
setlocal
node "%~dp0runner_selftest.js"
exit /b %ERRORLEVEL%
