@echo off
rem Issue 1777 (Ship Exteriors V2) GPU ms at 4K, RULEBOOK 3.9 (FRAMETIME3): the #207 scene gate in its res_2160 mode
rem (3D drawn at 3840x2160, scaling_3d_scale 2.0, HUD at 1080p), 3 sessions, VS_SHIP_LOOK_V2=0 then =1 on ONE pinned
rem commit (opus/issue-1777 5736804b). FRAMETIME2 passed the 1080p half; its "4K" runs were 1080p again, because the
rem gate always sizes its window to 1920x1080 and --resolution does not change that; res_2160 is the gate's own 4K mode.
rem The GPU must be SOLO (R293). Done when: V2 on adds no GPU regression at 4K beyond session noise and stays inside
rem 12.5 ms. Built from opus_job_template.bat; once queued it is never edited.
setlocal EnableExtensions
set "JOB=opus1777ft4k"
set "LABEL=1777"
set "TOOLS=godot"
set "PIN_NEW=5736804b5950832bcffb780cf9a3476a1f747179"
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
call :gate off2160 0
call :gate on2160 1
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one gate run: switch setting. Every Godot start goes through job_wrap.
:gate
set "O=%OJ_OUT%\out_gate_%1"
if not exist "%O%" mkdir "%O%"
set "VS_SHIP_LOOK_V2=%2"
set "JW_STEP=gate %1" & set "JW_EXPECT=%O%\scene_gate.json" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%" --sessions 3 --modes res_2160 --build-wait-s 300 > "%O%\run.txt" 2>&1
if not exist "%O%\scene_gate.json" call "%JW%" fail "gate %1 wrote no scene_gate.json (see %O%\run.txt)"
set "VS_SHIP_LOOK_V2="
exit /b 0
