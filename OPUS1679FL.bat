@echo off
rem Issue 1679 (R411 P1b, fleet lighting, merged in PR 1704 behind VS_FLEET_LIGHTING=1): the Pick Sheet pictures.
rem One pinned commit (main 907a07fa plus the look bench --fleet-cams option and the sheet maker, c11312ed), the
rem PC-built hulls from build\godot, then the look bench fleet part twice on the same checkout: flag off (today) and
rem flag on (1679). Cameras 170, 110 and 60, every sky. Then the stock fleet sheets (all 36 hulls at camera 170, off vs
rem on) and the six-faction pick sheets (contrib\opus\looks_1122\fl1679_sheet.py), plus the Chorus "before" pictures
rem for issue 1683. Stills only (shared GPU claim, R276). Writes only its own attempt folder; publishes nothing.
setlocal EnableExtensions
set "JOB=opus1679fl"
set "LABEL=1679"
set "TOOLS=godot pil"
set "PIN_NEW=c11312ed9ee378873bbf21ae2390e9175dcf221d"
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
set "BA=--path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn --"
set "PICTURE_SOURCE_REPO=%OJ_REPO%"
set "VS_FLEET_LIGHTING="
set "JW_STEP=bench flag off" & set "JW_EXPECT=%O%\bench_off\bench.json" & call "%JW%" run 3600 "%JW_GODOT%" %BA% --out "%O%\bench_off" --commit c11312ed --part fleet --fleet-cams 170,110,60 > "%O%\bench_off.txt" 2>&1
set "VS_FLEET_LIGHTING=1"
set "JW_STEP=bench flag on" & set "JW_EXPECT=%O%\bench_on\bench.json" & call "%JW%" run 3600 "%JW_GODOT%" %BA% --out "%O%\bench_on" --commit c11312ed --part fleet --fleet-cams 170,110,60 > "%O%\bench_on.txt" 2>&1
set "VS_FLEET_LIGHTING="
set "JW_STEP=stock fleet sheets" & set "JW_EXPECT=%O%\sheets_stock" & call "%JW%" run 1800 "%JW_PIL%" "%OJ_REPO%\tools\pc\jobs\look_bench_sheets.py" --after "%O%\bench_on" --before "%O%\bench_off" --out "%O%\sheets_stock" --label-after fl1679_on --label-before fl1679_off > "%O%\sheets_stock.txt" 2>&1
set "JW_STEP=pick sheets" & set "JW_EXPECT=%O%\sheets\summary.txt" & call "%JW%" run 1800 "%JW_PIL%" "%OJ_REPO%\contrib\opus\looks_1122\fl1679_sheet.py" --off "%O%\bench_off" --on "%O%\bench_on" --out "%O%\sheets" > "%O%\sheets.txt" 2>&1
exit /b 0
