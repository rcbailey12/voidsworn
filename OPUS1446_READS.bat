@echo off
rem Issue 1446: the three battle reads (ROUTE-1 shield routing, ARC-1 an inspected enemy's arcs and reach, REINF-1 the
rem reinforcement edge) at camera 170 with the built hulls, one picture each. Runs the registered check
rem scenes/battle/test/battle_reads_1446_check.gd windowed with --shots; it also prints PASS or FAIL lines.
rem Made from tools/pc/jobs/opus_job_template.bat. Once queued, never edited: a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1446"
set "LABEL=1446"
set "TOOLS=godot"
set "PIN_NEW=4caa895522fd6af87ba80f1d823777a01d7f9463"
set "PIN_OLD="
set "OJ_NEED_HULLS=H7_23 H8_23 V14_23 V15_37"

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
if not exist "%O%\shots" mkdir "%O%\shots"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
set "JW_STEP=%1 reads shots" & set "JW_EXPECT=%O%\shots\ROUTE-1.png;%O%\shots\ARC-1.png;%O%\shots\REINF-1.png" & call "%JW%" run 900 "%JW_GODOT%" --windowed --resolution 1920x1080 --path "%OJ_REPO%\godot" --script res://scenes/battle/test/battle_reads_1446_check.gd -- --shots "%O%\shots" > "%O%\reads_1446.txt" 2>&1
exit /b 0
