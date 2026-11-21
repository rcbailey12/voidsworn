@echo off
rem MEASURE3 replaces MEASURE2 (its selftest failed: a -f format inside $o.Add() split into Add arguments). MEASURE2 replaced MEASURE: GPU memory joins the game pid.
rem Issue 1439 (Astra items 3 and 6): first-launch cost and graphics memory per stage, before any fix. Measurement only.
rem Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat (issue 1303). GPU solo (frame-time measurement).
rem Steps on one pinned commit (opus/issue-1439: godot/bench/perf_1439.gd and a 4-line hook in main.gd):
rem   1. checkout, ships, import, then a Windows release export of that checkout into the attempt folder.
rem   2. cold_1 and cold_2: the exported game, each in its own fresh throwaway profile (so Godot's shader cache and the
rem      driver cache under LOCALAPPDATA start empty), the fresh profile's own settings (fullscreen, Max, 4x MSAA), driven
rem      through title, map and Battles 1 to 3 on route seed 10. A route that stops early is logged in its summary.
rem   3. battle24: the same commit run from the checkout (test scenarios are not exported): scenario s25, 24 ships that
rem      play themselves to the end (load, 24 ships, the kills), fresh profile, same settings.
rem Every game run has Windows' own dedicated and shared GPU memory sampled once a second (gpu_mem_sampler.ps1, counters
rem only; the game's own process id joins them), then summarize.ps1 writes summary.txt. selftest.ps1 checks that join on a
rem fixture first. The game opens fullscreen on the main screen for each run.
rem Results: Downloads\voidsworn_test\opus1439\out_<stamp>_<n>\out_new\<run>\summary.txt. Once queued, never edited.
setlocal EnableExtensions
set "JOB=opus1439"
set "LABEL=1439"
set "TOOLS=godot"
set "PIN_NEW=6581a07c147e7fecdc9ab8c17392b657349857b5"
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
set "PF=%OJ_REPO%\contrib\opus\perf_1120_firstlaunch"
rem ---- the Windows scripts' acceptance check on a fixture (two processes, one unreadable sample) before any GPU run
powershell -NoProfile -ExecutionPolicy Bypass -File "%PF%\selftest.ps1" > "%O%\selftest.txt" 2>&1
findstr /b /c:"SELFTEST OK" "%O%\selftest.txt" > nul
if errorlevel 1 (call "%JW%" fail "%1 selftest: see selftest.txt" & exit /b 1)
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if defined JW_STOP exit /b 0
rem ---- the release export, as g2_export.bat makes it, into this attempt folder (the live build\export is not touched)
set "TPL=%APPDATA%\Godot\export_templates\4.7.2.stable"
if not exist "%TPL%\windows_release_x86_64.exe" (call "%JW%" fail "%1 export: no export templates in %TPL%" & exit /b 1)
set "PC_GODOT_EXPORT_TEMPLATES=%TPL%"
set "EXP=%O%\export"
if not exist "%EXP%" mkdir "%EXP%"
set "JW_STEP=%1 export" & set "JW_EXPECT=%EXP%\Voidsworn.pck" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --export-release "Windows Desktop" "%EXP%\Voidsworn.exe" > "%O%\export.txt" 2>&1
set "PC_GODOT_EXPORT_TEMPLATES="
if defined JW_STOP exit /b 0
call :game %1 cold_1
call :game %1 cold_2
call :game %1 battle24
exit /b 0

rem ---- one game run: sampler on, launch time noted, the game under the watchdog (GPU solo), sampler off, summary.
rem cold_N: the exported console exe on route seed 10. battle24: the checkout's Godot on scenario s25.
:game
if defined JW_STOP exit /b 0
set "R=%O%\%2"
if not exist "%R%" mkdir "%R%"
start "" /b powershell -NoProfile -ExecutionPolicy Bypass -File "%PF%\gpu_mem_sampler.ps1" -Out "%R%\gpu.csv" -Stop "%R%\stop.txt" -MaxSeconds 2400
set "LMS="
for /f %%T in ('powershell -NoProfile -Command "[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()"') do set "LMS=%%T"
set "PC_GPU_MODE=solo"
set "JW_CONTINUE=1"
set "JW_STEP=%1 %2"
set "JW_EXPECT=%R%\summary.json"
if /i "%2"=="battle24" call "%JW%" run 1200 "%JW_GODOT%" --path "%OJ_REPO%\godot" -- --scenario s25 --perf-1439 "%R%" --launch-ms %LMS% --quit-after 1000 > "%R%\log.txt" 2>&1
if /i not "%2"=="battle24" call "%JW%" run 1800 "%EXP%\Voidsworn.console.exe" -- --perf-1439 "%R%" --player-path-seed 10 --launch-ms %LMS% --quit-after 1600 > "%R%\log.txt" 2>&1
set "PC_GPU_MODE="
echo stop> "%R%\stop.txt"
powershell -NoProfile -Command "Start-Sleep -Seconds 3"
if not exist "%R%\summary.json" exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -File "%PF%\summarize.ps1" -Run "%R%" > "%R%\summary_log.txt" 2>&1
if not exist "%R%\summary.txt" (set "JW_CONTINUE=1" & call "%JW%" fail "%1 %2 summary: see summary_log.txt")
exit /b 0
