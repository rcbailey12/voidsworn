@echo off
rem Issue 1528 and 1558 (Opus): first-salvo frame time before (main 1a000813) and after (opus/issue-1558 3e967d81), RUN8 layout, plus rocket salvo shots at the battle camera for the jets (1558 item 1). From issue 1303's template for a helper (Opus) PC proof bat. Copy it to /mnt/project-files/board/<issue>/pc/<NAME>.bat,
rem fill the five lines marked FILL, write the steps, and send it to the Board. The Board checks only that the bat
rem calls the head (opus_job_head.bat: tools_live watchdog, exact pins, fresh checkout per attempt, safe ships copy with
rem the tracked-file check, throwaway Godot profiles, Ryan's options hashed before and after). Once queued, a bat is
rem never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1558a"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1528"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=3e967d818e1dd3b31029370f85474dff5c7cbec6"
set "PIN_OLD=1a000813476a855163b5cd76af627198097a405b"

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
rem ---- STEPS (issues 1528 and 1558). The game as it ships, no option switches.
rem A: frame time through every salvo, no pictures, twice each (RUN8 layout): Navy seed 3, Hullbreakers seed 7.
rem Done when (1528): no frame over 33 ms on the first salvo of each battle on the new pin (old pin: 135 to 145 ms).
set "VS_1379_PD="
set "VS_1379_OLD="
for %%R in (hegemony_3 corsair_7) do (
  for /f "tokens=1-2 delims=_" %%a in ("%%R") do (
    for %%N in (1 2) do (
      if not exist "%O%\ft_%%R_%%N" mkdir "%O%\ft_%%R_%%N"
      set "JW_STEP=%1 ft %%R %%N" & set "JW_EXPECT=%O%\ft_%%R_%%N\run.txt" & call "%JW%" run 1500 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1920x1080 res://scenes/battle/battle.tscn -- --torp-shots "%O%\ft_%%R_%%N" --torp-ft --fac %%a --obj ambush --map open --seed %%b --movement brisk --quit-after 900 > "%O%\ft_%%R_%%N\run.txt" 2>&1
    )
  )
)
rem B: Hullbreakers rocket salvos at the battle camera (0) and at 40: the launch jets and hits, for 1558 item 1.
for %%R in (corsair_7_0 corsair_7_40) do (
  for /f "tokens=1-3 delims=_" %%a in ("%%R") do (
    if not exist "%O%\shots_%%R" mkdir "%O%\shots_%%R"
    set "JW_STEP=%1 shots %%R" & set "JW_EXPECT=%O%\shots_%%R\run.txt" & call "%JW%" run 1500 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1920x1080 res://scenes/battle/battle.tscn -- --torp-shots "%O%\shots_%%R" --torp-cam %%c --fac %%a --obj ambush --map open --seed %%b --movement brisk --quit-after 900 > "%O%\shots_%%R\run.txt" 2>&1
  )
)
exit /b 0
