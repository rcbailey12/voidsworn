@echo off
rem Issue 1468 (Opus helper): shader math before and after on the NVIDIA card. PIN_NEW is the head of PR 1475
rem (branch opus/issue-1468), PIN_OLD its main base. Both pins shoot the same scenes:
rem   world_shots.tscn, default battle camera (c170), 1920x1080, Forward+, quality max: world_planet (galaxy band and
rem   textured planet), frontier_station (a second planet) and deadstar (black hole lensing glow and photon ring).
rem   shader_math_shots.gd (PR 1475's capture, full size bakes): sky panorama, band view, one relief planet from front,
rem   back and a turned check. PIN_OLD has no copy of that script, so the job saves PR 1475's copy during the new run,
rem   puts it into the old checkout for the old run and deletes its own copy after.
rem Outputs: out_new\* and out_old\* (same file names). Built from tools/pc/jobs/opus_job_template.bat.
rem Once queued, never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1468"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1468"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=b33f782040f3fad735371411d63263062cde2f11"
set "PIN_OLD=0f634a50ed8f53e1216f9dea79521e476b7729b2"

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
if errorlevel 1 exit /b %ERRORLEVEL%
call :one old %PIN_OLD%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships, import, then the job's own steps. Every Godot start goes through job_wrap.
:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "SMS=%OJ_REPO%\godot\world\shader_math_shots.gd"
set "SMS_KEEP=%OJ_OUT%\shader_math_shots.gd"
set "SMS_OURS=0"
if "%1"=="new" (
  if not exist "%SMS%" (echo FAILED: no shader_math_shots.gd on PIN_NEW & exit /b 1)
  copy /y "%SMS%" "%SMS_KEEP%" >nul
)
if "%1"=="old" (
  if exist "%SMS%" (echo FAILED: PIN_OLD already has shader_math_shots.gd & exit /b 1)
  if not exist "%SMS_KEEP%" (echo FAILED: no saved shader_math_shots.gd & exit /b 1)
  copy /y "%SMS_KEEP%" "%SMS%" >nul
  set "SMS_OURS=1"
)
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
rem ---- STEPS: the battle scenes at c170, then the shader math capture
set "JW_STEP=%1 world_shots" & set "JW_EXPECT=%O%\deadstar_1_default.jpg" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://world/world_shots.tscn -- --out "%O%" --only world_planet,frontier_station,deadstar --quality max > "%O%\world_shots_log.txt" 2>&1
set "JW_STEP=%1 shader_math" & set "JW_EXPECT=%O%\planet_game_turned_%1.png" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1280x720 --script res://world/shader_math_shots.gd -- --out "%O%" --tag %1 > "%O%\shader_math_log.txt" 2>&1
if "%SMS_OURS%"=="1" del /q "%SMS%"
if "%SMS_OURS%"=="1" if exist "%SMS%" (echo FAILED: our shader_math_shots.gd copy still in the old checkout & exit /b 1)
exit /b 0
