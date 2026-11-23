@echo off
rem Issue 1394 acid tell, 1394J (Wave 0, Fable and Astra Nov 23: the 1394I tell spots read close to the banned soft green
rem bloom). Before/after look bench of acid (melt) kills on the new hulls: Warden, Penitent (Sunward), Harvester (Eclipse),
rem Raider (Hullbreakers), Dominion (Navy), each hit by acid at two points on its top plating, then killed with cause melt,
rem at the battle camera, close up, and a new grazing camera (about 10 degrees over the plating) through the tell.
rem new = PR 1858 0a95e335 (etched patch edge, rim under the glow threshold); old = PR 1730 4e55e152 (the 1394I look).
rem The capture script comes from the new pin (contrib/opus/melt_1394/capture.gd) and is copied to the job folder so the
rem old pin runs the same script. Sheets are built in the cloud by contrib/opus/melt_1394/sheet.py (real sample times,
rem pins stamped). From tools/pc/jobs/opus_job_template.bat. Nothing on the PC is deleted. GPU: look bench.
setlocal EnableExtensions
set "JOB=opus1394meltj"
set "LABEL=1394"
set "TOOLS=godot"
set "PIN_NEW=0a95e335ff4d5e03bc6350325edc3d90c1241425"
set "PIN_OLD=4e55e15241141a09209ca2463016e3beedd82e19"

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
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
if "%1"=="new" copy /y "%OJ_REPO%\contrib\opus\melt_1394\capture.gd" "%OJ_OUT%\capture1394.gd" > nul
if not exist "%OJ_OUT%\capture1394.gd" (echo FAILED: no capture script & exit /b 1)
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
set "JW_STEP=%1 melt bench" & set "JW_EXPECT=%O%\scratch\%1_capture.json;%O%\scratch\%1_penitent_c170\core_sheet.jpg;%O%\scratch\%1_warden_c170\core_sheet.jpg" & call "%JW%" run 1500 "%JW_GODOT%" --fixed-fps 60 --windowed --resolution 1920x1080 --path "%OJ_REPO%\godot" --script "%OJ_OUT%\capture1394.gd" -- "%O%\scratch" warden,penitent,d_harvester,c_raider,h_dominion %1 > "%O%\log_bench.txt" 2>&1
exit /b 0
