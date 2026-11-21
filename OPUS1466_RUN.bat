@echo off
rem Issue 1466 (PR 1476): wreck debris physics, the PC proof. Built from tools/pc/jobs/opus_job_template.bat on
rem opus_job_head.bat (issue 1303). Lean (Board, Nov 21: PC drive low): box stand-ins only, so no ships copy, no release
rem export, no player path; runs from the head's own pinned checkouts, which the tail drops after a PASS.
rem Per arm (NEW = PR 1476 head, OLD = its main base), GPU solo (R293):
rem   1. death-frame cost: fx/test/destruction_fleet_probe.gd twice (20 box ships, 20 staged kills, Forward+ 1920x1080);
rem   2. the c60 crossing: fx/test/wreck_crossing_shot.gd (a box frigate drives through a dead frigate's settled plates):
rem      frames, sheet.png, crossing.json; crossing.mp4 when an ffmpeg is on PATH (otherwise the frames stay).
rem NEW also runs the headless wreck_contact_check. OLD's copy of the shot script (it is new in PR 1476) is copied in
rem from the NEW checkout and removed after its run, so the OLD checkout holds no work.
rem PASS needs: NEW wreck_contact_check passes; NEW fleet.txt and crossing.json written; NEW moved at least one plate.
rem OLD steps are evidence only (optional). Once queued, never edited: a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1466"
set "LABEL=1466"
set "TOOLS=godot"
set "PIN_NEW=ec823accecc891d6c1e5bf6516afc591065c332c"
set "PIN_OLD=080b7b55903167e1665aaf85e7cdf7192d13434e"

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

set "FF="
where ffmpeg > nul 2>&1 && set "FF=ffmpeg"
if not defined FF call "%JW%" note "no ffmpeg on PATH: the crossing frames stay as jpgs for the cloud to encode"

call :one new %PIN_NEW%
if defined PIN_OLD call :one old %PIN_OLD%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, import, then the job's own steps. Every Godot start goes through job_wrap.
:one
call "%HEAD%" checkout %1 %2
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
rem job_wrap clears JW_OPTIONAL after every run, so each OLD step sets it again (OLD is evidence only)
if /i "%1"=="old" set "JW_OPTIONAL=1"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
set "SHOT=res://fx/test/wreck_crossing_shot.gd"
if /i "%1"=="new" (
  set "JW_STEP=new wreck_contact_check" & set "JW_EXPECT=%O%\wreck_contact_check.txt" & call "%JW%" run 600 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --script res://fx/test/wreck_contact_check.gd > "%O%\wreck_contact_check.txt" 2>&1
)
if /i "%1"=="old" (
  if not exist "%OJ_REPO%\godot\bench\opus1466" mkdir "%OJ_REPO%\godot\bench\opus1466"
  copy /y "%OJ_OUT%\new\godot\fx\test\wreck_crossing_shot.gd" "%OJ_REPO%\godot\bench\opus1466\wreck_crossing_shot.gd" > nul
  set "SHOT=res://bench/opus1466/wreck_crossing_shot.gd"
)
set "PC_GPU_MODE=solo"
for %%N in (1 2) do call :fleet %1 %%N
set "PSHORT=%2"
set "C=%O%\crossing"
if not exist "%C%" mkdir "%C%"
if /i "%1"=="new" set "JW_EXPECT=%C%\crossing.json"
if /i "%1"=="old" set "JW_OPTIONAL=1"
set "JW_STEP=%1 crossing c60" & call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1280x720 --fixed-fps 60 --script %SHOT% -- "%C%" "%1 %PSHORT:~0,10%" > "%O%\log_crossing.txt" 2>&1
set "PC_GPU_MODE="
for /f "delims=" %%L in ('findstr /c:"WRECK_CROSSING" "%O%\log_crossing.txt" 2^>nul') do call "%JW%" note "%1 %%L"
if /i "%1"=="new" (
  findstr /c:"\"moved\": 0," "%C%\crossing.json" > nul 2>&1
  if not errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "new crossing moved no plate")
)
if defined FF if exist "%C%\frames\f_000.jpg" "%FF%" -y -loglevel error -framerate 30 -i "%C%\frames\f_%%03d.jpg" -c:v libx264 -pix_fmt yuv420p -crf 20 "%C%\crossing.mp4" > "%O%\ffmpeg.txt" 2>&1
if /i "%1"=="old" del /q "%OJ_REPO%\godot\bench\opus1466\wreck_crossing_shot.gd" "%OJ_REPO%\godot\bench\opus1466\wreck_crossing_shot.gd.uid" > nul 2>&1
if /i "%1"=="old" rmdir "%OJ_REPO%\godot\bench\opus1466" > nul 2>&1
if /i "%1"=="old" rmdir "%OJ_REPO%\godot\bench" > nul 2>&1
exit /b 0

:fleet
set "F=%O%\fleet%2"
if not exist "%F%" mkdir "%F%"
set "PROBE_OUT=%F%"
if /i "%1"=="new" set "JW_EXPECT=%F%\fleet.txt"
if /i "%1"=="old" set "JW_OPTIONAL=1"
set "JW_STEP=%1 fleet cost %2" & call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script res://fx/test/destruction_fleet_probe.gd > "%F%\log_fleet.txt" 2>&1
set "PROBE_OUT="
for /f "delims=" %%L in ('findstr /c:"DESTRUCTION_FLEET" "%F%\fleet.txt" 2^>nul') do call "%JW%" note "%1 fleet%2 %%L"
exit /b 0
