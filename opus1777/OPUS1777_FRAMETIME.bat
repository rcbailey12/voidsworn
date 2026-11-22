@echo off
rem Issue 1777 (Ship Exteriors V2) frame time, RULEBOOK 3.9: the #207 scene gate (20 ships, every faction, HUD up, effects
rem on), base mode, 3 sessions, VS_SHIP_LOOK_V2=0 then =1 on ONE pinned commit (opus/issue-1777 b0768e6b): frame median
rem at 1920x1080 and GPU ms at 3840x2160. The GPU must be SOLO for this job (R293): the Board queues it with no other GPU
rem job running. Done when: V2 on stays inside 12.5 ms of 16.7 at 1080p and adds no GPU regression beyond session noise
rem at 4K. Built from opus_job_template.bat; once queued it is never edited.
setlocal EnableExtensions
set "JOB=opus1777ft"
set "LABEL=1777"
set "TOOLS=godot"
set "PIN_NEW=b0768e6b6e498121e0c3f630f84704636355d00f"
set "PIN_OLD="

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

call "%HEAD%" checkout new %PIN_NEW%
call "%HEAD%" ships
set "JW_STEP=import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%OJ_OUT%\import.txt" 2>&1
call :gate off 0 1920x1080
call :gate on 1 1920x1080
call :gate off4k 0 3840x2160
call :gate on4k 1 3840x2160
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one gate run: switch setting, resolution. Every Godot start goes through job_wrap.
:gate
set "O=%OJ_OUT%\gate_%1"
if not exist "%O%" mkdir "%O%"
set "VS_SHIP_LOOK_V2=%2"
set "JW_STEP=gate %1" & set "JW_EXPECT=%O%\scene_gate.json" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --resolution %3 res://bench/scene_gate.tscn -- --out "%O%" --sessions 3 --modes base > "%O%\run.txt" 2>&1
if not exist "%O%\scene_gate.json" call "%JW%" fail "gate %1 wrote no scene_gate.json (see %O%\run.txt)"
set "VS_SHIP_LOOK_V2="
exit /b 0
