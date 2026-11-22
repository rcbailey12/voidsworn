@echo off
rem Issue 1361 (World V2, R419; R420 band 3): asteroids and crystals on the live world, before (VS_1361_OLD=1, main's
rem look drawn from main's own rock files in the old checkout) and after (switch off) on ONE commit of the new code.
rem bench/rock_bench.tscn builds world/world.gd exactly as a battle does and saves, per run, under out_<run>\rocks:
rem   RK_<kind>_c170.png and RK_<kind>_c26.png for stone, iron, carbon, ice, crystal (a blocker cluster with debris hexes)
rem   RK_crystal_cluster_c26.png (camera 26 tipped low onto a crystal blocker's clusters)
rem   frame_time.json (a full 37-hex crystal belt at camera 170: mean and p95 GPU ms over 600 frames)
rem Each still is 1280x720 at 1 to 1, stamped with its name, revision and stage (tools/picture_provenance.gd).
rem A missing still or row fails the bench (exit 4, ROCKS_FAILED.txt) and this job.
rem SOLO: the frame-time row needs the GPU alone (RULEBOOK 3.4, R293); queue with nothing else on the GPU.
rem B (Artoo on PR 1782): pinned to 3a8f3e75, where the bench first proves its rock set (8 old scans with scan_07 and 3
rem crystals before, 6 and 4 after, no fallback mesh) and fails closed otherwise. Replaces OPUS1361_ROCKS.bat, never
rem queued. Old rock files from e4b7d034 (main at the PR's merge base).
rem Queue only after green checks and a passed review (R407). Built from opus_job_template.bat.
setlocal EnableExtensions
set "JOB=opus1361rocksd"
set "LABEL=1361"
set "TOOLS=godot"
set "PIN_NEW=1af7368ea438cddb90b502eb05fd7d7cd2f390eb"
set "PIN_OLD=e4b7d03438d3266a207f71bf2eed8e905ded71ae"
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

rem the old checkout only supplies main's rock files; nothing runs from it
call "%HEAD%" checkout old %PIN_OLD%
set "OLD_ROCKS=%OJ_REPO%\godot\world\rocks"
if not exist "%OLD_ROCKS%\scan_07.glb" (call "%JW%" fail "old checkout has no scan_07.glb at %OLD_ROCKS%" & exit /b 1)
if not exist "%OLD_ROCKS%\scans.json" (call "%JW%" fail "old checkout has no scans.json" & exit /b 1)
call "%HEAD%" checkout new %PIN_NEW%
call "%HEAD%" ships
set "JW_STEP=import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%OJ_OUT%\import.txt" 2>&1
if not exist "%OJ_REPO%\godot\world\rocks\crystal_03.glb" (call "%JW%" fail "new checkout has no crystal_03.glb" & exit /b 1)
if exist "%OJ_REPO%\godot\world\rocks\scan_07.glb" (call "%JW%" fail "new checkout still has scan_07.glb" & exit /b 1)
set "JW_STEP=rock gate" & set "JW_EXPECT=%OJ_OUT%\rock_gate.txt" & call "%JW%" run 600 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --script res://world/test/rock_scan_check.gd > "%OJ_OUT%\rock_gate.txt" 2>&1
call :run before 1
call :run after 0
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one switch setting: the rock bench. Every Godot start goes through job_wrap.
:run
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "VS_1361_OLD=%2"
set "VS_1361_OLD_DIR="
if "%2"=="1" set "VS_1361_OLD_DIR=%OLD_ROCKS%"
set "JW_STEP=%1 rock bench" & set "JW_EXPECT=%O%\rocks" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/rock_bench.tscn -- --out "%O%" --commit %PIN_NEW% --frames 600 > "%O%\bench_log.txt" 2>&1
if exist "%O%\ROCKS_FAILED.txt" call "%JW%" fail "%1 rock set incomplete (see %O%\ROCKS_FAILED.txt)"
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "%1 bench did not finish (see %O%\bench_log.txt)"
for %%K in (stone iron carbon ice crystal) do (
  if not exist "%O%\rocks\RK_%%K_c170.png" call "%JW%" fail "%1 missing RK_%%K_c170.png"
  if not exist "%O%\rocks\RK_%%K_c26.png" call "%JW%" fail "%1 missing RK_%%K_c26.png"
)
if not exist "%O%\rocks\RK_crystal_cluster_c26.png" call "%JW%" fail "%1 missing RK_crystal_cluster_c26.png"
if not exist "%O%\rocks\frame_time.json" call "%JW%" fail "%1 missing frame_time.json"
set "VS_1361_OLD=" & set "VS_1361_OLD_DIR="
exit /b 0
