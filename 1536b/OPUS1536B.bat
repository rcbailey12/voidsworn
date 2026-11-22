@echo off
rem Issue 1303: the template for a helper (Opus) PC proof bat. Copy it to /mnt/project-files/board/<issue>/pc/<NAME>.bat,
rem fill the five lines marked FILL, write the steps, and send it to the Board. The Board checks only that the bat
rem calls the head (opus_job_head.bat: tools_live watchdog, exact pins, fresh checkout per attempt, safe ships copy with
rem the tracked-file check, throwaway Godot profiles, Ryan's options hashed before and after). Once queued, a bat is
rem never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1536b"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1536"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=35e0cd74c52c16dfc141253dc718f55ea23fd153"
set "PIN_OLD=c36c156c3a0dac77fc8fe858baf12da4c8f8fe0e"
rem Issue 1536: the Navy relay beacon (O3_11) under the hold hex. NEW is opus/issue-1536, OLD is main before it.
rem Two real Hold battles per pin (bots play to the end), shots at the fixed moments of battle.gd --shots.
rem B over A: the battle scene opens on its own (res://scenes/battle/battle.tscn), not through the title. In A the
rem title took over when the battle ended and its backdrop battle saved over the same shot names (A kept title pictures).
rem Alone, the battle saves 01 to 09_end and quits with 0. NEW also logs "[board] relay beacon ready in".
set "OJ_NEED_HULLS=O3_11"

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
rem ---- STEPS (issue 1536): two Hold battles at the battle camera, 2560x1440, the same seeds on both pins.
set "JW_STEP=%1 hold_open" & set "JW_EXPECT=%O%\hold_open\09_end.png" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" res://scenes/battle/battle.tscn --rendering-method forward_plus --resolution 2560x1440 -- --seed 4242 --obj hold --map open --shots "%O%\hold_open" --quit-after 900 > "%O%\hold_open.txt" 2>&1
set "JW_STEP=%1 hold_belt" & set "JW_EXPECT=%O%\hold_belt\09_end.png" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" res://scenes/battle/battle.tscn --rendering-method forward_plus --resolution 2560x1440 -- --seed 1536 --obj hold --map belt --shots "%O%\hold_belt" --quit-after 900 > "%O%\hold_belt.txt" 2>&1
exit /b 0
