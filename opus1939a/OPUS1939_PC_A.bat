@echo off
rem PC_A (Nov 24): issue 1939, terran and volcanic detail pass (seam fix, equator tilt, live fine detail, richer recipes).
rem From tools/pc/jobs/opus_job_template.bat, steps as OPUS1765_PC_I. Run it with the GPU solo: the timing step is a
rem frame-time measurement (R293, RULEBOOK 3.4). Two pins: new = the branch head, old = main at its base.
rem Per pin:
rem   1. import
rem   2. shots: the five board planet looks at camera 170 and close, 1280x720, stamped by picture_provenance; fresh cache.
rem   3. timing: the five board looks at camera 170, 1920x1080, 600 frames of GPU render time each; fresh cache.
rem   4. new pin only: battle load, cold then warm, seeds 5 to 9 on the planet map, into one fresh bake cache folder
rem      made for this job (VS_WORLD_CACHE); nothing in the user cache is read or deleted. Each run saves its planet still.
setlocal EnableExtensions
set "JOB=opus1939a"
set "LABEL=1939"
set "TOOLS=godot"
set "PIN_NEW=138ef288b2a774108a9d1ba99df885c1b5cf511e"
set "PIN_OLD=decf4fd5d64cd05b4a4659855aea7da13758a06d"
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

call :one new %PIN_NEW%
call :one old %PIN_OLD%
set "VS_WORLD_CACHE="
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
set "TAG=after"
if /i "%1"=="old" set "TAG=before"
set "VS_WORLD_CACHE=%O%\cache_shots"
if not exist "%VS_WORLD_CACHE%" mkdir "%VS_WORLD_CACHE%"
set "JW_STEP=%1 shots" & set "JW_CONTINUE=1" & set "JW_EXPECT=%O%\shots\board_0_c170_%TAG%.png;%O%\shots\board_5_close_%TAG%.png" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1280x720 --script res://world/planet_v2_shots.gd -- --out "%O%\shots" --tag %TAG% --only board > "%O%\shots.txt" 2>&1
set "VS_WORLD_CACHE=%O%\cache_timing"
if not exist "%VS_WORLD_CACHE%" mkdir "%VS_WORLD_CACHE%"
set "JW_STEP=%1 timing" & set "JW_CONTINUE=1" & set "JW_EXPECT=%O%\timing\board_5_c170_%TAG%.png" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1920x1080 --script res://world/planet_v2_shots.gd -- --out "%O%\timing" --tag %TAG% --only board --timing 600 > "%O%\timing.txt" 2>&1
if /i "%1"=="old" goto :one_end
set "VS_WORLD_CACHE=%O%\cache_battle"
if not exist "%VS_WORLD_CACHE%" mkdir "%VS_WORLD_CACHE%"
for %%S in (5 6 7 8 9) do call :battle %1 %%S cold
for %%S in (5 6 7 8 9) do call :battle %1 %%S warm
:one_end
set "VS_WORLD_CACHE="
exit /b 0

:battle
set "JW_STEP=%1 battle seed %2 %3" & set "JW_CONTINUE=1" & set "JW_EXPECT=%O%\battle_s%2_%3.png" & call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1280x720 res://scenes/battle/battle.tscn -- --map planet --seed %2 --planet-shot "%O%\battle_s%2_%3.png" > "%O%\battle_s%2_%3.txt" 2>&1
exit /b 0
