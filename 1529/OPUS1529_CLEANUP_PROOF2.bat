@echo off
rem PR 1529 proof 2 (Opus): munition maps stay embedded on import; images in godot/fx/munitions keep the checkout (Artoo on PR 1529). From issue 1303's template for a helper (Opus) PC proof bat. Copy it to /mnt/project-files/board/<issue>/pc/<NAME>.bat,
rem fill the five lines marked FILL, write the steps, and send it to the Board. The Board checks only that the bat
rem calls the head (opus_job_head.bat: tools_live watchdog, exact pins, fresh checkout per attempt, safe ships copy with
rem the tracked-file check, throwaway Godot profiles, Ryan's options hashed before and after). Once queued, a bat is
rem never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1529b"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1379"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot node pil"
rem the preflight finds pil only through PIL_PYTHON on this PC (as OPUS1516_COLLECT_PROOF_B)
if not defined PIL_PYTHON set "PIL_PYTHON=%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=b1a6213af306fd8ed0aa0c755463bb5e27267162"
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
rem ---- STEPS (PR 1529 proof 2).
rem 1. After the head's import: list godot/fx/munitions. It must hold only the two glbs, their .glb.import files and
rem    README.md (no extracted .jpg or .png).
rem 2. The runner fault matrix (runner_selftest.js, Windows), with the two new munition-image fixtures (kept, bytes survive).
rem 3. The Opus job head tests (static checks on Windows; the pwsh fixtures are issue 1530).
rem 4. The embedded maps in the game: Navy seed 3 at camera 40, the frames RUN8 took, to compare the torpedo's paint.
set "PYTHON=%JW_PIL%"
dir /b "%OJ_REPO%\godot\fx\munitions" > "%O%\munitions_after_import.txt" 2>&1
set "JW_STEP=%1 runner_selftest" & set "JW_EXPECT=%O%\runner_selftest.txt" & call "%JW%" run 1800 "%JW_NODE%" "%OJ_REPO%\tools\pc\runner_selftest.js" > "%O%\runner_selftest.txt" 2>&1
set "JW_STEP=%1 opus_job_head_tests" & set "JW_EXPECT=%O%\opus_job_head_tests.txt" & call "%JW%" run 600 "%JW_NODE%" "%OJ_REPO%\contrib\opus\tools\opus_job_head_tests.js" > "%O%\opus_job_head_tests.txt" 2>&1
set "VS_1379_PD="
set "VS_1379_OLD="
if not exist "%O%\shots_hegemony_3_40" mkdir "%O%\shots_hegemony_3_40"
set "JW_STEP=%1 shots hegemony_3_40" & set "JW_EXPECT=%O%\shots_hegemony_3_40\run.txt" & call "%JW%" run 1500 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1920x1080 res://scenes/battle/battle.tscn -- --torp-shots "%O%\shots_hegemony_3_40" --torp-cam 40 --fac hegemony --obj ambush --map open --seed 3 --movement brisk --quit-after 900 > "%O%\shots_hegemony_3_40\run.txt" 2>&1
dir /b "%OJ_REPO%\godot\fx\munitions" > "%O%\munitions_after_run.txt" 2>&1
exit /b 0
