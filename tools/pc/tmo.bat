@echo off
rem Run a program with a time limit: tmo.bat <seconds> <exe> [args ...]
rem Kills the whole process tree if it overruns (exit code 124, logged to Downloads\voidsworn_test\queue\logs\timeouts.log);
rem otherwise returns the program's own exit code. Its output comes out here, so "tmo.bat ... > log.txt 2>&1" captures it.
rem For agent runs set TMO_REPO, TMO_OUT and TMO_LOG. The seconds argument is then the hard ceiling (runners default
rem to 21600), and STALL_MIN (default 30) stops a run only after no file, commit or log progress. TMO_ERR_LOG is optional.
rem A stopped agent writes resume.txt and stop_reason.txt in TMO_OUT. Clear these TMO variables before runner checks.
setlocal
set "TMO_ARGS=%*"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_timeout.ps1"
exit /b %ERRORLEVEL%
