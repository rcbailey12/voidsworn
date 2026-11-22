@echo off
rem Issue 1480: picture RET-1, the campaign map after a real retreat (fleet back on the stop it jumped from, the fight
rem still on the map), with the built hulls. Runs campaign/test/retreat_map_1480_shots.gd windowed; it prints RET1_STATE
rem and fails if the fleet is not back or the fight is used up.
rem Made from tools/pc/jobs/opus_job_template.bat. Once queued, never edited: a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1480"
set "LABEL=1480"
set "TOOLS=godot"
set "PIN_NEW=9395c44a5f371676d2810cbcb84cec57dab2e740"
set "PIN_OLD="
set "OJ_NEED_HULLS=B19_11 B20_11 H10_23 I14_23 I15_11 I8_37 V14_23 V15_37 V16_37"

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
set "JW_STEP=%1 RET-1 shot" & set "JW_EXPECT=%O%\RET-1_map_after_retreat.png" & call "%JW%" run 900 "%JW_GODOT%" --windowed --resolution 1920x1080 --path "%OJ_REPO%\godot" --script res://campaign/test/retreat_map_1480_shots.gd -- "%O%" --no-tips > "%O%\ret1_1480.txt" 2>&1
exit /b 0
