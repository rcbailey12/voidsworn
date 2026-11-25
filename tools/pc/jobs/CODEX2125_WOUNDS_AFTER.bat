@echo off
rem Issue 2125: queue after All checks and independent review pass on the exact pin (R407).
rem Use CODEX2125_WOUNDS_AFTER.bat with the full reviewed commit, or fill PIN_NEW for a double-click launch.
rem Same DEFAULT_B wounds rows and 4K 20-hull fleet, with VS_WOUNDS_V2=1 only.
setlocal EnableExtensions
set "JOB=codex2125woundsafter"
set "LABEL=2125"
set "TOOLS=godot"
set "PIN_NEW=%~1"
if not defined PIN_NEW (echo Supply the full reviewed issue 2125 commit. & exit /b 2)
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=gpu"
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
set "O=%OJ_OUT%\out_after"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=import"
call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if errorlevel 1 goto done
set "VS_WOUNDS_V2=1"
set "JW_STEP=wounds V2 bench"
set "JW_EXPECT=%O%\moments"
call "%JW%" run 5400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%" --part moments --moments res://bench/look_moments_wounds_v2.json > "%O%\bench_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "wounds bench did not finish (see %O%\bench_log.txt)"

set "PC_GPU_MODE=solo"
set "DAMAGE_OUT=%O%\fleet"
set "DAMAGE_MODE=fleet"
set "DAMAGE_LABEL=after"
set "DAMAGE_GATE_WOUNDS=1"
set "DAMAGE_PROFILE_WOUNDS=1"
set "JW_STEP=fleet frame time and wound pass profile"
set "JW_EXPECT=%DAMAGE_OUT%\fleet.json"
call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --disable-vsync --windowed --resolution 1920x1080 --script res://fx/test/damage_surface_probe.gd > "%O%\fleet_log.txt" 2>&1
:done
call "%HEAD%" tail
exit /b %ERRORLEVEL%
