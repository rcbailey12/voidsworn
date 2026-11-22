@echo off
rem Issue 1395 RUN2 (replaces OPUS1395_RUN.bat if it has not run; Artoo on PR 1596): adds the cut start-to-ready time.
rem Big-kill frame times before and after, GPU solo (R293), Forward+, real installed A16 (C19_51).
rem OLD = main before the fix, NEW = the fix (worker-measured wreck reach). fx/test/death_cost_check.gd comes from the
rem NEW pin and is copied into the OLD checkout after its ships step (main has no such file; it is untracked there). On
rem OLD its two "worker reach" lines FAIL by design (the old code has none; VS_1395_BASELINE=1 keeps the exit 0); the
rem frame lines are what we compare.
rem Three runs per pin, windowed 1920x1080, vsync off. Look for: the worst frames between 1.5 s and 4 s after the kill
rem (the wreck draw-in), and the "reach ... face_read" number (the main-thread cost the fix removes).
rem Built from tools/pc/jobs/opus_job_template.bat (issue 1303). Board: repin NEW to the frozen board pin if you use one.
setlocal EnableExtensions
set "JOB=opus1395b"
set "LABEL=1395"
set "TOOLS=godot"
set "PIN_NEW=1ecbc9c3e760186f834b03bc1472aef22d86bae0"
set "PIN_OLD=1a000813476a855163b5cd76af627198097a405b"

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
call :one old %PIN_OLD%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if /i "%1"=="new" set "CHK=%OJ_REPO%\godot\fx\test\death_cost_check.gd"
set "VS_1395_BASELINE="
if /i "%1"=="old" set "VS_1395_BASELINE=1"
if /i "%1"=="old" if defined CHK copy /y "%CHK%" "%OJ_REPO%\godot\fx\test\death_cost_check.gd" > nul
if not exist "%OJ_REPO%\godot\fx\test\death_cost_check.gd" (call "%JW%" fail "%1 check file missing" & exit /b 1)
if not exist "%OJ_REPO%\godot\assets\ships\C19_51\C19_51.glb" (call "%JW%" fail "%1 has no installed C19_51 (A16)" & exit /b 1)
for %%R in (1 2 3) do (
  set "JW_STEP=%1 death cost run %%R" & call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --disable-vsync --windowed --resolution 1920x1080 --script res://fx/test/death_cost_check.gd > "%O%\death_cost_%%R.txt" 2>&1
  findstr /c:"DEATH_COST failures=" "%O%\death_cost_%%R.txt" > nul || call "%JW%" fail "%1 run %%R did not finish (see %O%\death_cost_%%R.txt)"
)
exit /b 0
