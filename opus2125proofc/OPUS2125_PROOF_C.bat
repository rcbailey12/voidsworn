@echo off
rem Issue 2125 proof C, for the head with the Chorus interior fix (run 2). Queue ONLY with the reviewed green pin (R407).
rem Usage: OPUS2125_PROOF_C.bat <full 40-char commit>
rem 1) the six-ship wounds rows with VS_WOUNDS_V2=1 (Ryan's final sheets; the Chorus wreck inside changed since PROOF_A)
rem 2) the 20-hull fleet: V2 off first as the same-run baseline (no profile, no gate), then V2 on (gate 12.5 ms p99,
rem    then the wound-pass profile, which runs after the gate samples). GPU solo. Replaces PROOF_B.
setlocal EnableExtensions
set "JOB=opus2125proofc"
set "LABEL=2125"
set "TOOLS=godot"
set "PIN_NEW=%~1"
if not defined PIN_NEW (echo FAILED: give the full reviewed issue 2125 commit & exit /b 2)
set "OJ_NEED_HULLS=V16_37 H10_23 C15s_23 B21_11 I15_11 D21_23"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (echo FAILED: no tools_live\current.txt & exit /b 2)
set "HEAD=%VT%\tools_live\%TLV%\pc\jobs\opus_job_head.bat"
if not exist "%HEAD%" (echo FAILED: no head at "%HEAD%" & exit /b 2)
call "%HEAD%" init "%JOB%" "%LABEL%" "%TOOLS%"
if errorlevel 1 exit /b %ERRORLEVEL%
call "%HEAD%" checkout new "%PIN_NEW%"
if errorlevel 1 goto done
call "%HEAD%" ships
if errorlevel 1 goto done
set "JW_STEP=import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%OJ_OUT%\import.txt" 2>&1
if errorlevel 1 goto done

set "O=%OJ_OUT%\out_after"
if not exist "%O%" mkdir "%O%"
set "VS_WOUNDS_V2=1"
set "JW_STEP=after wounds bench" & set "JW_EXPECT=%O%\moments"
call "%JW%" run 5400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%" --part moments --moments res://bench/look_moments_wounds_v2.json > "%O%\bench_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "after bench did not finish (see %O%\bench_log.txt)"

set "PC_GPU_MODE=solo"
call :fleet before 0
call :fleet after 1
:done
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:fleet
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "VS_WOUNDS_V2=%2"
set "DAMAGE_OUT=%O%\fleet" & set "DAMAGE_MODE=fleet" & set "DAMAGE_LABEL=%1"
set "DAMAGE_GATE_WOUNDS=" & set "DAMAGE_PROFILE_WOUNDS="
if "%2"=="1" set "DAMAGE_GATE_WOUNDS=1" & set "DAMAGE_PROFILE_WOUNDS=1"
set "JW_STEP=%1 fleet frame time" & set "JW_EXPECT=%O%\fleet\fleet.json"
call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --disable-vsync --windowed --resolution 1920x1080 --script res://fx/test/damage_surface_probe.gd > "%O%\fleet_log.txt" 2>&1
set "DAMAGE_MODE=" & set "VS_WOUNDS_V2=" & set "DAMAGE_GATE_WOUNDS=" & set "DAMAGE_PROFILE_WOUNDS="
exit /b 0
