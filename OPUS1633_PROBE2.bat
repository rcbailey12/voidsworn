@echo off
rem Issue 1633 PROBE2 (replaces PROBE, pin df387cd6): does the first big death still stall about 2 s after the battle's own fx warm-up?
rem RUN2 for 1395 showed a 2.2 to 2.3 s frame 0.07 s after the A16 kill in every run, with fx.step only about 1 ms of it
rem (engine side). That check had no warm-up. This runs fx/test/death_cost_check.gd on one pin, three runs with --warm
rem (fx.warmup first, as battle.gd _warmup does) and two cold runs, alternating. GPU solo (R293), Forward+, windowed
rem 1920x1080, vsync off, real installed A16 (C19_51). Look for: "DEATH_COST frames ... worst=" and "DEATH_COST pipelines"
rem (now split per frame into what fx.step compiles and what the draw compiles, plus "pipelines in the kill call").
rem No fix in this job; the fix follows only if the warm runs still stall.
rem Built from tools/pc/jobs/opus_job_template.bat (issue 1303).
setlocal EnableExtensions
set "JOB=opus1633b"
set "LABEL=1633"
set "TOOLS=godot"
set "PIN_NEW=df387cd67770c118b86a35794ceb752232455d28"
set "PIN_OLD="

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
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if not exist "%OJ_REPO%\godot\assets\ships\C19_51\C19_51.glb" (call "%JW%" fail "%1 has no installed C19_51 (A16)" & exit /b 1)
for %%R in (warm1 cold1 warm2 cold2 warm3) do (
  set "MODE="
  if /i "%%R"=="warm1" set "MODE=--warm"
  if /i "%%R"=="warm2" set "MODE=--warm"
  if /i "%%R"=="warm3" set "MODE=--warm"
  call :run %1 %%R
)
exit /b 0

:run
set "JW_STEP=%1 death %2" & call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --disable-vsync --windowed --resolution 1920x1080 --script res://fx/test/death_cost_check.gd -- %MODE% > "%O%\death_%2.txt" 2>&1
findstr /c:"DEATH_COST failures=" "%O%\death_%2.txt" > nul || call "%JW%" fail "%1 %2 did not finish (see %O%\death_%2.txt)"
exit /b 0
