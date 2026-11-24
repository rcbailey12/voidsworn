@echo off
rem PC_J (Nov 23): same as PC_G on 69563a9d, where the board planet queues its maps before the sky (PC_I seed 8 froze).
rem Issue 1765 (Planets V2, PR 1776): cold-load recheck after PC_F. PC_F (248be0e2) froze the volcanic board planet on its
rem cold load (seed 8, 24.2 s, stand-in kept). 30a4ee53 makes the arc bake about a quarter cheaper. This job runs the new
rem pin only: import, then the real battle on the planet map for seeds 5 to 9, cold then warm, each into one fresh bake
rem cache folder made for this job (VS_WORLD_CACHE), so nothing in the user cache is read or deleted. No shots, no
rem timing, no old pin. Run it with the GPU solo, as load times are measured.
setlocal EnableExtensions
set "JOB=opus1765j"
set "LABEL=1765"
set "TOOLS=godot"
set "PIN_NEW=69563a9d99f1fa3ad6e47e5a146a1c0e6ad7b278"
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
set "VS_WORLD_CACHE="
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
set "VS_WORLD_CACHE=%O%\cache_battle"
if not exist "%VS_WORLD_CACHE%" mkdir "%VS_WORLD_CACHE%"
for %%S in (5 6 7 8 9) do call :battle %1 %%S cold
for %%S in (5 6 7 8 9) do call :battle %1 %%S warm
set "VS_WORLD_CACHE="
exit /b 0

:battle
set "JW_STEP=%1 battle seed %2 %3" & set "JW_CONTINUE=1" & set "JW_EXPECT=%O%\battle_s%2_%3.png" & call "%JW%" run 900 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1280x720 res://scenes/battle/battle.tscn -- --map planet --seed %2 --planet-shot "%O%\battle_s%2_%3.png" > "%O%\battle_s%2_%3.txt" 2>&1
exit /b 0
