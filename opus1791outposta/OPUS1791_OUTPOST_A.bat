@echo off
rem Issue 1791 (Ryan, Nov 24 2026: "Yes agree on 1", "Yes outpost"): build, install and capture the station outpost, the
rem smaller station from T2's own kit and paint that now stands in the 3-hex teaching cluster and the 1-hex station hole.
rem One job, three steps on one pinned commit:
rem   1 build    Blender runs tools/blender/kits/hegemony_station/outpost_production.py: T2's paint route on the outpost kit
rem              at T2's kit-to-world size, with T2's own painted tiles read from the installed station_T2.glb (--t2-glb;
rem              no new tile bake, CPU only, a few minutes). Writes station_outpost.glb.
rem   2 install  Godot runs outpost_install.gd: caches gen\ships\station_outpost.scn in the job's checkout and reads back
rem              both small spots (they must pick the outpost) and the big 19-hex spot (it must keep T2).
rem   3 capture  bench/look_bench.gd --part props, AFTER only: read ST1_teaching_3hex and ST3_hole_1hex at cameras 170
rem              and 26 (bench.json: each station's scale and dock count); ST2_big_19hex must be unchanged T2.
rem Kept in out_new\outpost: station_outpost.glb, station_outpost.scn, outpost_manifest.json, the painted .blend and the
rem logs. Nothing is published: once Ryan accepts the pictures, the Board copies the glb to
rem build\godot\assets\ships\station_outpost\ and the scn to build\godot\gen\ships\. Queue after green checks (R407).
setlocal EnableExtensions
set "JOB=opus1791outposta"
set "LABEL=1791"
set "TOOLS=godot blender"
set "PIN_NEW=30c277fccb1ab40282e750510841efa90e04038f"
set "PIN_OLD="
set "OJ_SLOTS=0"
set "OJ_SLOT_KIND=gpu"

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
set "O=%OJ_OUT%\out_new"
set "K=%O%\outpost"
if not exist "%K%" mkdir "%K%"
set "KIT=%OJ_REPO%\tools\blender\kits\hegemony_station"
set "JW_STEP=import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
if not exist "%OJ_REPO%\godot\gen\ships\station_T2.scn" (call "%JW%" fail "station_T2.scn missing from the copied gen" & exit /b 1)
if not exist "%OJ_REPO%\godot\assets\ships\station_T2\station_T2.glb" (call "%JW%" fail "station_T2.glb missing: the outpost takes its painted tiles from it" & exit /b 1)

rem ---- 1 build: T2's paint route on the outpost kit (GPU bake of the tiles, then paint and export)
set "JW_STEP=build outpost" & set "JW_EXPECT=%K%\station_outpost.glb" & call "%JW%" run 7200 "%JW_BLENDER%" -b -t 8 --python-exit-code 1 -P "%KIT%\outpost_production.py" -- --out "%K%" --project "%OJ_REPO%\godot" --t2-glb "%OJ_REPO%\godot\assets\ships\station_T2\station_T2.glb" > "%K%\build_log.txt" 2>&1
findstr /c:"OUTPOST PRODUCTION COMPLETE" "%K%\build_log.txt" > nul || call "%JW%" fail "outpost build did not finish (see %K%\build_log.txt)"

rem ---- 2 install: cache the scene in this checkout only and read back the three spots
set "JW_STEP=install outpost" & set "JW_EXPECT=%OJ_REPO%\godot\gen\ships\station_outpost.scn" & call "%JW%" run 900 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --script "%KIT%\outpost_install.gd" -- "%K%\station_outpost.glb" > "%K%\install_log.txt" 2>&1
findstr /c:"OUTPOST INSTALL READBACK PASS" "%K%\install_log.txt" > nul || call "%JW%" fail "outpost install readback failed (see %K%\install_log.txt)"
if exist "%OJ_REPO%\godot\gen\ships\station_outpost.scn" copy /y "%OJ_REPO%\godot\gen\ships\station_outpost.scn" "%K%\" > nul

rem ---- 3 capture: the props part of the look bench, after pass only
set "JW_STEP=after props bench" & set "JW_EXPECT=%O%\props" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%" --part props --commit %PIN_NEW% > "%O%\bench_log.txt" 2>&1
if exist "%O%\PROPS_FAILED.txt" call "%JW%" fail "props set incomplete (see %O%\PROPS_FAILED.txt)"
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "bench did not finish (see %O%\bench_log.txt)"
call "%HEAD%" tail
exit /b %ERRORLEVEL%
