@echo off
rem R431 (Ryan Nov 23 2026: every Glasswright reads as I8_37) BEFORE pictures: the Glasswright hulls as they are published in
rem Ryan's game today (the ships step copies them from build\godot), drawn by a4_shots at camera 170 and 26 (VS_A4_RADII)
rem with Ship Look V2 on (the pin holds PR 1786, V2 on by default), plus the strike craft's close set. The AFTER pictures come
rem from the OPUS431_<ship>_RUN.bat rebuilds (same a4_shots sets); the thread builds the labelled sheets from both relays.
rem Light GPU job (a4_shots only, no bake). Built from opus_job_template.bat; once queued it is never edited.
setlocal EnableExtensions
set "JOB=opus431before"
set "LABEL=1777"
set "TOOLS=godot"
set "PIN_NEW=906d2b480e01c6c95bfc8f6f391fba61ef5a79b7"
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
rem commas split call arguments in cmd, so the code lists travel in variables
set "SH_CODES=I8_37,I16_11,I15_11,I11_37,I14_23" & call :shots ships ithar cams
set "SH_CODES=ithar_GV2,ithar_GW4" & call :shots craft craft close
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one a4_shots run: out folder, faction set, shot set (codes in SH_CODES). Every Godot start goes through job_wrap.
:shots
set "O=%OJ_OUT%\out_before_%1"
if not exist "%O%" mkdir "%O%"
set "VS_A4_RADII=170,26"
set "PICTURE_SOURCE_REPO=%OJ_REPO%"
set "JW_STEP=before %1" & set "JW_EXPECT=%O%" & call "%JW%" run 1200 "%JW_GODOT%" --path "%OJ_REPO%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%" --facs %2 --sets %3 --codes %SH_CODES% --tag before > "%O%\shots_log.txt" 2>&1
set "VS_A4_RADII="
exit /b 0
