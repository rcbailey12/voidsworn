@echo off
rem Run a program with a time limit: tmo.bat <seconds> <exe> [args ...]
rem Kills the whole process tree on ceiling, idle, or a fatal step log line (exit 124, reason and child logs in timeouts.log).
rem Otherwise returns the program's exit code. Stdout and stderr still go to the caller, so > log.txt 2>&1 captures both.
rem TMO_STEP names this step in timeouts.log. TMO_STEP_OUT watches for new files (defaults to --out, if supplied).
rem The Jolt job-system line is fatal. TMO_FATAL_PATTERN adds a case-insensitive regex for this step only.
rem The step idle limit is 300 s for Godot and 600 s for other tools. TMO_IDLE_S may raise it for a single step.
rem For agent runs set TMO_REPO, TMO_OUT and TMO_LOG. The seconds argument is then the hard ceiling (runners default
rem to 21600), and STALL_MIN (default 30) stops a run only after no file, commit or log progress. TMO_ERR_LOG is optional.
rem A stopped agent writes resume.txt and stop_reason.txt in TMO_OUT. Clear these TMO variables before runner checks.
rem R293: shared capacity is in Downloads\voidsworn_test\gpu_slots.json, e.g. {"sharedSlots":4}, default 2.
rem Godot GPU commands weigh 1, Blender commands weigh 2; PC_GPU_WEIGHT overrides the weight for this command.
rem For a CPU-only Blender command set PC_GPU_MODE=none. Godot still classifies its own GPU work.
rem Timing scripts take solo once per command and wait for all slots. The step ceiling applies to its claim.
rem PC_GPU_SOLO_MAX_S can set an earlier limit measured from claim acquisition.
rem For other GPU executables set PC_GPU_MODE=shared, or solo for timing. Waiting does not spend the command's limit.
rem Godot and Voidsworn get a fresh profile in job scratch. PC_REAL_PROFILE=1 keeps the caller's profile.
rem Issue 1194: one watchdog for every lane and job. Any other copy of this file hands the step to the canonical copy named
rem by Downloads\voidsworn_test\tools_live\current.txt (lane_tools_refresh.ps1 -Build tools_live), so an old build\tools or
rem branch checkout never runs its own slot reader. Only when no tools_live folder exists at all (before the first install)
rem does it run its own copy. Once it exists, a blank pointer or a version without run_timeout.ps1 stops the step with
rem exit 125 and runs nothing (fail closed). Self-tests (PC_RUNNER_TEST=1) and TMO_OWN_COPY=1 run this copy.
setlocal EnableExtensions DisableDelayedExpansion
set "TMO_ARGS=%*"
set "TMO_PS=%~dp0run_timeout.ps1"
set "TMO_LIVE=%USERPROFILE%\Downloads\voidsworn_test\tools_live"
set "TMO_VER="
if exist "%TMO_LIVE%\current.txt" set /p TMO_VER=<"%TMO_LIVE%\current.txt"
if "%PC_RUNNER_TEST%"=="1" goto run
if "%TMO_OWN_COPY%"=="1" goto run
if not exist "%TMO_LIVE%\" goto run
if not defined TMO_VER goto broken
if /i "%~dp0"=="%TMO_LIVE%\%TMO_VER%\pc\" goto run
if not exist "%TMO_LIVE%\%TMO_VER%\pc\run_timeout.ps1" goto broken
set "TMO_PS=%TMO_LIVE%\%TMO_VER%\pc\run_timeout.ps1"
:run
if "%TMO_SAY_WATCHDOG%"=="1" echo tmo: watchdog %TMO_PS%
powershell -NoProfile -ExecutionPolicy Bypass -File "%TMO_PS%"
exit /b %ERRORLEVEL%
:broken
echo tmo: tools_live is installed but current.txt names no usable watchdog ^(%TMO_LIVE%^); step not started
exit /b 125
