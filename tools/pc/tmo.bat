@echo off
rem Run a program with a time limit: tmo.bat <seconds> <exe> [args ...]
rem Kills the whole process tree if it overruns (exit code 124, logged to Downloads\voidsworn_test\queue\logs\timeouts.log);
rem otherwise returns the program's own exit code. Its output comes out here, so "tmo.bat ... > log.txt 2>&1" captures it.
rem For agent runs set TMO_REPO, TMO_OUT and TMO_LOG. The seconds argument is then the hard ceiling (runners default
rem to 21600), and STALL_MIN (default 30) stops a run only after no file, commit or log progress. TMO_ERR_LOG is optional.
rem A stopped agent writes resume.txt and stop_reason.txt in TMO_OUT. Clear these TMO variables before runner checks.
rem R293: shared capacity is in Downloads\voidsworn_test\gpu_slots.json, e.g. {"sharedSlots":4}, default 2.
rem Godot GPU commands weigh 1, Blender commands weigh 2; PC_GPU_WEIGHT overrides the weight for this command.
rem Timing scripts take solo and wait for all slots, whatever the shared capacity.
rem For other GPU executables set PC_GPU_MODE=shared, or solo for timing. Waiting does not spend the command's limit.
setlocal
set "TMO_ARGS=%*"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_timeout.ps1"
exit /b %ERRORLEVEL%
