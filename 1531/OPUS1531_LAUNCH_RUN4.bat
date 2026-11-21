@echo off
rem Issue 1531 run 4 (Opus, replaces run 3): Sunward torpedo 0.7 s slide out of the hull and torpedoes drawn at half size, rockets at 0.7 (Ryan, Nov 21), new only
rem fill the five lines marked FILL, write the steps, and send it to the Board. The Board checks only that the bat
rem calls the head (opus_job_head.bat: tools_live watchdog, exact pins, fresh checkout per attempt, safe ships copy with
rem the tracked-file check, throwaway Godot profiles, Ryan's options hashed before and after). Once queued, a bat is
rem never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1531d"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1531"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=0c723f3a3d3a49a244072e0977c9aefa24e31e45"
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
rem ---- STEPS (issue 1531 run 4). Each battle captures the launch, close on the firing ship (--torp-launch), every
rem 0.067 s for 1.8 s. Navy seed 3: the Sunward Cinder torpedo; Hullbreakers seed 7: the rocket pods; Glasswrights seed 3:
rem the star torpedo. New at camera 26 (first 2 salvos) and at the battle camera with the cut-in kept (first salvo);
rem old (VS_1379_LAUNCH=old) at camera 26 (first salvo), for the before column.
set "VS_1379_PD="
set "VS_1379_OLD="
for %%R in (hegemony_3 corsair_7) do (
  for /f "tokens=1-2 delims=_" %%a in ("%%R") do (
    set "VS_1379_LAUNCH="
    if not exist "%O%\new26_%%R" mkdir "%O%\new26_%%R"
    set "JW_STEP=%1 new26 %%R" & set "JW_EXPECT=%O%\new26_%%R\run.txt" & call "%JW%" run 1500 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1920x1080 res://scenes/battle/battle.tscn -- --torp-shots "%O%\new26_%%R" --torp-launch --torp-dt 0.067 --torp-max 2 --torp-cam 26 --fac %%a --obj ambush --map open --seed %%b --movement brisk --quit-after 900 > "%O%\new26_%%R\run.txt" 2>&1
  )
)
set "VS_1379_LAUNCH="
exit /b 0
