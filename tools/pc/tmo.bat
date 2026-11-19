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
setlocal EnableExtensions DisableDelayedExpansion
set "TMO_ARGS=%*"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_timeout.ps1"
exit /b %ERRORLEVEL%
