@echo off
rem Issue 1767 (World V2, R419; R420 band 3): stations and hulks on the live board, before (VS_1767_OLD=1) and after
rem (VS_1767_OLD=0) on ONE commit, at cameras 170 and 26. bench/look_bench.gd --part props draws render/board.gd itself:
rem   ST1_teaching_3hex  the teaching cluster (T2 fitted and level after; banked O1_37 before), a cruiser in the notch hex
rem   ST2_big_19hex      the big cluster (unchanged T2) with a cruiser in the next hex out: the ring lamp's spill
rem   ST3_hole_1hex      a lone station hole (T2 fitted in one hex after; O1_37 before), a cruiser next to it
rem   HK0_graveyard      31 hulk hexes at camera 170; then HK_<faction> per faction drawn, at 170 and 26
rem Each still is 1280x720 at 1 to 1, stamped with its name, revision and stage (tools/picture_provenance.gd).
rem O (Fable's review at 7c734f53, Nov 24): pinned to f4981c0d. N's dull dead metal, plus the scorch layer keeps
rem the hull's normal map, own-faction wrecks, shared station fit and paint. Read HK_hegemony c170 and c26, HK_corsair
rem c26, HK0_graveyard c170, ST1 and ST3 at both cameras; bench.json: each station's scale and dock count. Replaces N.
rem AFTER pass only: the before pictures from PROPS_E (relay pc-out-opus1767propse) stand, the old path did not change.
rem The props part still draws every row; the hulk rows (HK_*, HK0) are the ones to read. Queue after green checks (R407).
setlocal EnableExtensions
set "JOB=opus1767propso"
set "LABEL=1767"
set "TOOLS=godot"
set "PIN_NEW=f4981c0d17f29a451ee0bf1e053180934b3a3ab9"
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
set "JW_STEP=import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%OJ_OUT%\import.txt" 2>&1
if not exist "%OJ_REPO%\godot\gen\ships\station_T2.scn" (call "%JW%" fail "station_T2.scn missing from the copied gen" & exit /b 1)
call :run after 0
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one switch setting: the props part of the look bench. Every Godot start goes through job_wrap.
:run
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "VS_1767_OLD=%2"
set "JW_STEP=%1 props bench" & set "JW_EXPECT=%O%\props" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%" --part props --commit %PIN_NEW% > "%O%\bench_log.txt" 2>&1
if exist "%O%\PROPS_FAILED.txt" call "%JW%" fail "%1 props set incomplete (see %O%\PROPS_FAILED.txt)"
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "%1 bench did not finish (see %O%\bench_log.txt)"
set "VS_1767_OLD="
exit /b 0
