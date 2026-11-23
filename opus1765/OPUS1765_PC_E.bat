@echo off
rem Issue 1765 (Planets V2, PR 1776): PC proof, from tools/pc/jobs/opus_job_template.bat. Run it with the GPU solo: the
rem timing step is a frame-time measurement (R293, RULEBOOK 3.4). Two pins: new = the PR head, old = main at its merge base.
rem Per pin:
rem   1. import
rem   2. shots: the five board planet looks at camera 170 and close, their stand-ins (new pin only), the eight backdrop
rem      planets and four moons, 1280x720,
rem      every frame stamped by picture_provenance; the new pin fails if any body leaves R420 band 2. Fresh bake cache.
rem   3. timing: the five board looks at camera 170, 1920x1080, 600 frames of GPU render time each, plus video memory and
rem      static memory peak (the [timing] lines). Fresh bake cache.
rem   4. battle load, cold then warm: a real battle opened on the planet map for seeds 5 to 9 (board looks rocky, terran,
rem      ice, volcanic, barren), each into one fresh bake cache folder made for this job (VS_WORLD_CACHE), so nothing in
rem      the user cache is read or deleted; the warm pass reuses that folder. The [planet] line gives the planet's load
rem      time, its surface, video memory and memory peak; the step time in status.txt gives the whole entry. Each run
rem      saves the battle camera's planet still.
rem The old pin has no [planet] line and, opened as the main scene, its sky bakes fail (the busy-root bug this PR fixes);
rem its battle rows are context only.
setlocal EnableExtensions
set "JOB=opus1765e"
set "LABEL=1765"
set "TOOLS=godot"
set "PIN_NEW=916da8cdf86eeff17d2c3271e9f76fb94cae814c"
set "PIN_OLD=af3254003371af87d58c497676cf0c407bb411c8"
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
rem the shot script is new in this PR: the new pin keeps a copy, the old pin gets it as an untracked file
if /i "%1"=="new" copy /y "%OJ_REPO%\godot\world\planet_v2_shots.gd" "%OJ_OUT%\planet_v2_shots.gd" > nul
if /i "%1"=="old" copy /y "%OJ_OUT%\planet_v2_shots.gd" "%OJ_REPO%\godot\world\planet_v2_shots.gd" > nul
if not exist "%OJ_REPO%\godot\world\planet_v2_shots.gd" (call "%JW%" fail "%1 shot script missing" & exit /b 1)
set "TAG=after"
if /i "%1"=="old" set "TAG=before"
set "MOON_LAST=moon_3"
rem the old pin draws two moon looks only (moon_0, moon_1): PC_C failed expecting moon_3 there
if /i "%1"=="old" set "MOON_LAST=moon_1"
set "VS_WORLD_CACHE=%O%\cache_shots"
if not exist "%VS_WORLD_CACHE%" mkdir "%VS_WORLD_CACHE%"
set "JW_STEP=%1 shots" & set "JW_CONTINUE=1" & set "JW_EXPECT=%O%\shots\board_0_c170_%TAG%.png;%O%\shots\%MOON_LAST%_%TAG%.png" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1280x720 --script res://world/planet_v2_shots.gd -- --out "%O%\shots" --tag %TAG% > "%O%\shots.txt" 2>&1
set "VS_WORLD_CACHE=%O%\cache_timing"
if not exist "%VS_WORLD_CACHE%" mkdir "%VS_WORLD_CACHE%"
set "JW_STEP=%1 timing" & set "JW_CONTINUE=1" & set "JW_EXPECT=%O%\timing\board_5_c170_%TAG%.png" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1920x1080 --script res://world/planet_v2_shots.gd -- --out "%O%\timing" --tag %TAG% --only board --timing 600 > "%O%\timing.txt" 2>&1
set "VS_WORLD_CACHE=%O%\cache_battle"
if not exist "%VS_WORLD_CACHE%" mkdir "%VS_WORLD_CACHE%"
for %%S in (5 6 7 8 9) do call :battle %1 %%S cold
for %%S in (5 6 7 8 9) do call :battle %1 %%S warm
set "VS_WORLD_CACHE="
exit /b 0

:battle
set "JW_STEP=%1 battle seed %2 %3" & set "JW_CONTINUE=1" & set "JW_EXPECT=%O%\battle_s%2_%3.png" & call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1280x720 res://scenes/battle/battle.tscn -- --map planet --seed %2 --planet-shot "%O%\battle_s%2_%3.png" > "%O%\battle_s%2_%3.txt" 2>&1
exit /b 0
