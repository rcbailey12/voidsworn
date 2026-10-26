@echo off
rem Run a program with a time limit: tmo.bat <seconds> <exe> [args ...]
rem Kills the whole process tree if it overruns (exit code 124, logged to Downloads\voidsworn_test\queue\logs\timeouts.log);
rem otherwise returns the program's own exit code. Its output comes out here, so "tmo.bat ... > log.txt 2>&1" captures it.
setlocal
set "TMO_ARGS=%*"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_timeout.ps1"
exit /b %ERRORLEVEL%
