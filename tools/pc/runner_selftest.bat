@echo off
rem Free Windows proof for issue 687. Logs and tiny fixture repos stay in TEMP. No commits, pushes or model calls.
setlocal
node "%~dp0runner_selftest.js"
exit /b %ERRORLEVEL%
