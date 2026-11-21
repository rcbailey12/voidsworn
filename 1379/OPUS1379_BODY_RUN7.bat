@echo off
rem Issue 1379 run 7 (Opus): shot-down options for Ryan (VS_1379_PD old, A, B, C) on the real hulls, Navy seed 3, wider camera. From issue 1303's template for a helper (Opus) PC proof bat. Copy it to /mnt/project-files/board/<issue>/pc/<NAME>.bat,
rem fill the five lines marked FILL, write the steps, and send it to the Board. The Board checks only that the bat
rem calls the head (opus_job_head.bat: tools_live watchdog, exact pins, fresh checkout per attempt, safe ships copy with
rem the tracked-file check, throwaway Godot profiles, Ryan's options hashed before and after). Once queued, a bat is
rem never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1379h"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1379"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=bf0dff0c7f4d86b543d0e334474f1fbac80fdc32"
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
rem ---- STEPS (issue 1379 run 7): four shot-down looks (old, A, B, C) at two cameras (40 wide, 26 close).
set "VS_1379_OLD="
rem Navy seed 3: the Harrow's first torpedo is shot down by point defence, the next one hits the hull (same battle)
for %%S in (old A B C) do (
  set "VS_1379_PD=%%S"
  for %%C in (40 26) do (
    if not exist "%O%\pd_%%S_%%C" mkdir "%O%\pd_%%S_%%C"
    set "JW_STEP=%1 pd %%S cam %%C" & set "JW_EXPECT=%O%\pd_%%S_%%C\run.txt" & call "%JW%" run 1500 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1920x1080 res://scenes/battle/battle.tscn -- --torp-shots "%O%\pd_%%S_%%C" --torp-cam %%C --fac hegemony --obj ambush --map open --seed 3 --movement brisk --quit-after 600 > "%O%\pd_%%S_%%C\run.txt" 2>&1
  )
)
set "VS_1379_PD="
set "VS_1379_OLD="
exit /b 0
