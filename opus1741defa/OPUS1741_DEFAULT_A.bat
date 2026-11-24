@echo off
rem R416 (issue 1741) default-flip before and after pass (Ryan, Pick Sheet item 5, Nov 24): the six reference ships (V16_37, H10_23, C15s_23, B21_11, I15_11,
rem D21_23) at one heavy hit, 50% hull, 20% hull and death, cameras 170 and 26, before (VS_WOUNDS_V2=0) and after
rem (VS_WOUNDS_V2=1) on ONE commit, then the 20-hull frame-time gate (damage_surface_probe fleet) before and after.
rem Queue only after green checks and a passed review (R407). Built from opus_job_template.bat.
setlocal EnableExtensions
set "JOB=opus1741defa"
set "LABEL=1741"
set "TOOLS=godot"
set "PIN_NEW=7eb04d1101211533f935fecbf1165f1258e00531"
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

call "%HEAD%" checkout new %PIN_NEW%
call "%HEAD%" ships
set "JW_STEP=import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%OJ_OUT%\import.txt" 2>&1
if not exist "%OJ_REPO%\godot\bench\look_moments_wounds_v2.json" (call "%JW%" fail "rows file missing" & exit /b 1)
call :run before 0
call :run after 1
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one switch setting: the bench rows, then the fleet frame-time gate. Every Godot start goes through job_wrap.
:run
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "VS_WOUNDS_V2=%2"
set "JW_STEP=%1 wounds v2 bench" & set "JW_EXPECT=%O%\moments" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%" --part moments --moments res://bench/look_moments_wounds_v2.json > "%O%\bench_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "%1 bench did not finish (see %O%\bench_log.txt)"
set "DAMAGE_OUT=%O%\fleet" & set "DAMAGE_MODE=fleet" & set "DAMAGE_LABEL=%1"
set "JW_STEP=%1 fleet frame time" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --disable-vsync --windowed --resolution 1920x1080 --script res://fx/test/damage_surface_probe.gd > "%O%\fleet_log.txt" 2>&1
set "DAMAGE_MODE=" & set "VS_WOUNDS_V2="
exit /b 0
