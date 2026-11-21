@echo off
rem Issue 1379 run 5 (Opus): kit torpedo wake proof for PR 1416 (Artoo): motion at the battle camera, an interception, frame time. From issue 1303's template for a helper (Opus) PC proof bat. Copy it to /mnt/project-files/board/<issue>/pc/<NAME>.bat,
rem fill the five lines marked FILL, write the steps, and send it to the Board. The Board checks only that the bat
rem calls the head (opus_job_head.bat: tools_live watchdog, exact pins, fresh checkout per attempt, safe ships copy with
rem the tracked-file check, throwaway Godot profiles, Ryan's options hashed before and after). Once queued, a bat is
rem never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1379f"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1379"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=ac62b5015fced13638e5b10038acdf556b2c3c00"
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
rem ---- STEPS (issue 1379 run 5). A: frames, after and before (VS_1379_OLD=1): Hullbreaker rockets seed 7 at the close camera
rem (26) and at the battle camera (0); Navy seed 3, where point defence shoots down the Harrow's Sunward torpedo (cloud scan:
rem TORP_FIRE r1_x05 pd=1). B: frame time through every salvo with no pictures, after and before, Hullbreakers seed 7 (the
rem four-rocket salvos), twice each. The GPU is claimed solo by the head for the whole job.
for %%A in (after before) do (
  if "%%A"=="before" (set "VS_1379_OLD=1") else (set "VS_1379_OLD=")
  for %%R in (corsair_7_26 corsair_7_0 hegemony_3_26) do (
    for /f "tokens=1-3 delims=_" %%a in ("%%R") do (
      if not exist "%O%\%%A_%%R" mkdir "%O%\%%A_%%R"
      set "JW_STEP=%1 %%A %%R" & set "JW_EXPECT=%O%\%%A_%%R\run.txt" & call "%JW%" run 1500 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1920x1080 res://scenes/battle/battle.tscn -- --torp-shots "%O%\%%A_%%R" --torp-cam %%c --fac %%a --obj ambush --map open --seed %%b --movement brisk --quit-after 900 > "%O%\%%A_%%R\run.txt" 2>&1
    )
  )
  for %%N in (1 2) do (
    if not exist "%O%\ft_%%A_%%N" mkdir "%O%\ft_%%A_%%N"
    set "JW_STEP=%1 ft %%A %%N" & set "JW_EXPECT=%O%\ft_%%A_%%N\run.txt" & call "%JW%" run 1500 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1920x1080 res://scenes/battle/battle.tscn -- --torp-shots "%O%\ft_%%A_%%N" --torp-ft --fac corsair --obj ambush --map open --seed 7 --movement brisk --quit-after 900 > "%O%\ft_%%A_%%N\run.txt" 2>&1
  )
)
set "VS_1379_OLD="
exit /b 0
