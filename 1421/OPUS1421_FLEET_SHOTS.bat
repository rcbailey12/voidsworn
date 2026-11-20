@echo off
rem Issue 1421 fleet picture page (made from the issue 1303 template, opus_job_template.bat).
rem Issue 1303: the template for a helper (Opus) PC proof bat. Copy it to /mnt/project-files/board/<issue>/pc/<NAME>.bat,
rem fill the five lines marked FILL, write the steps, and send it to the Board. The Board checks only that the bat
rem calls the head (opus_job_head.bat: tools_live watchdog, exact pins, fresh checkout per attempt, safe ships copy with
rem the tracked-file check, throwaway Godot profiles, Ryan's options hashed before and after). Once queued, a bat is
rem never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1421"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1421"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=34834f97e00d0ebbebb628136e7ea3074e65f5b9"
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
rem ---- STEPS (issue 1421, the fleet picture page): one in-game picture of every faction ship as the shared install
rem (build\godot, copied in by the head's ships step) draws it today, alone at the battle camera's angle (a4_shots set
rem cams: <code>_cam170.jpg and <code>_cam60.jpg, true game pixels, hull code in the file name). Read only: nothing is
rem written to build\godot. One run per faction so a hang costs one faction, not the set.
for %%F in (voidsworn hegemony corsair chorus ithar deathless) do (
  if not exist "%O%\%%F" mkdir "%O%\%%F"
  set "JW_STEP=%1 shots %%F" & set "JW_EXPECT=" & call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\%%F" --facs %%F --sets cams > "%O%\%%F\log_shots.txt" 2>&1
)
exit /b 0
