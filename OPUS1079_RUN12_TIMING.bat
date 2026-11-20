@echo off
rem Issue 1079 run 12 (Opus worker; R334, the Board queues it): the nebula wake's cost on the merged head 23196329, where
rem Max now draws the bounded card path (PR 1297) that run 11 predates (Artoo on PR 1181). Storm-fixture timing only, GPU
rem solo: wake off and on alternated, max, high and low, 4K (and 1080p, which the same fixture also records), 3 sessions.
rem No clip, no stills, no scene gate. Built on the shared head (tools_live opus_job_head.bat: watchdog, exact pin, fresh
rem checkout, checked ships copy, throwaway profile, Ryan's options hashed before and after). Nothing is deleted.
rem Issue 1303: the template for a helper (Opus) PC proof bat. Copy it to /mnt/project-files/board/<issue>/pc/<NAME>.bat,
rem fill the five lines marked FILL, write the steps, and send it to the Board. The Board checks only that the bat
rem calls the head (opus_job_head.bat: tools_live watchdog, exact pins, fresh checkout per attempt, safe ships copy with
rem the tracked-file check, throwaway Godot profiles, Ryan's options hashed before and after). Once queued, a bat is
rem never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1079_run12"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1079"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=2319632911c7bb2fa5ba3c740b4185b22a8c2f33"
set "PIN_OLD="

rem The head is the installed main copy in tools_live (fail closed). OPUS_JOB_HEAD may name another copy only for a
rem pre-merge smoke, together with OPUS_JOB_HEAD_PREMERGE=1; the head logs that.
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "HEAD="
if defined OPUS_JOB_HEAD if not "%OPUS_JOB_HEAD_PREMERGE%"=="1" (echo FAILED: OPUS_JOB_HEAD is only for a pre-merge smoke & exit /b 2)
if "%OPUS_JOB_HEAD_PREMERGE%"=="1" set "HEAD=%OPUS_JOB_HEAD%"
set "TLV="
if not defined HEAD if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined HEAD if defined TLV set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not defined HEAD (echo FAILED: no tools_live\current.txt & exit /b 2)
if not exist "%HEAD%" (echo FAILED: no head at %HEAD% & exit /b 2)
call "%HEAD%" init "%JOB%" "%LABEL%" "%TOOLS%"
if errorlevel 1 exit /b %ERRORLEVEL%

call :one new %PIN_NEW%
if defined PIN_OLD call :one old %PIN_OLD%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships, import, then the job's own steps. Every Godot start goes through job_wrap.
:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
rem ---- STEPS: the storm-fixture timing, GPU solo (R293), as runs 8B to 11 measured it.
set "PC_GPU_MODE=solo"
nvidia-smi --query-gpu=name,driver_version,utilization.gpu,clocks.gr,clocks.mem,temperature.gpu,power.draw,pstate,memory.used --format=csv > "%O%\gpu.csv" 2>&1
set "JW_STEP=%1 storm timing" & set "JW_EXPECT=%O%\timing\results.json" & call "%JW%" run 3600 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script res://world/nebula_wake_capture.gd -- "%O%\timing" timing > "%O%\timing_log.txt" 2>&1
nvidia-smi --query-gpu=name,driver_version,utilization.gpu,clocks.gr,clocks.mem,temperature.gpu,power.draw,pstate,memory.used --format=csv,noheader >> "%O%\gpu.csv" 2>&1
exit /b 0
