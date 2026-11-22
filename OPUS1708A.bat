@echo off
rem Issue 1708 run A (Ryan, Nov 22: hide the bottom ship sheet during the scene, pop it back after). Same probe and pattern as
rem board/1589/pc/OPUS1589D.bat: godot/tools/probes/plan_commit_1589_shots.gd from the pinned checkout. PLN-1589_commit.jpg
rem should show no bottom sheet at +0.4, +1.6 and +3.0 s; GLS-1589.jpg panel 2 none, panel 3 the sheet back for the move
rem after firing. Also writes the plan, steps and enemy strips and both clips (mp4 when ffmpeg is found). Only the new pin
rem runs. Nothing on the PC is deleted. GPU: ordinary job.
setlocal EnableExtensions
set "JOB=opus1708a"
set "LABEL=1708"
set "TOOLS=godot ffmpeg"
set "PIN_NEW=015fe4d77f7a86ead25628a27721567ad7ca9449"

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
if not exist "%O%" mkdir "%O%"
set "JW_STEP=new import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
set "JW_STEP=new capture plan" & set "JW_EXPECT=%O%\PLN-1589_commit.jpg" & call "%JW%" run 900 "%JW_GODOT%" --windowed --resolution 1280x720 --write-movie "%O%\PLN-1589.avi" --fixed-fps 30 --path "%OJ_REPO%\godot" --script res://tools/probes/plan_commit_1589_shots.gd -- --out "%O%" --cam 170 --stage "PC, installed in game" > "%O%\log_plan.txt" 2>&1
if defined JW_FFMPEG if exist "%O%\PLN-1589.avi" "%JW_FFMPEG%" -y -loglevel error -i "%O%\PLN-1589.avi" -vf "fps=30,scale=1280:-2" -c:v libx264 -pix_fmt yuv420p -crf 26 -an "%O%\PLN-1589.mp4" > nul 2>&1
set "JW_STEP=new capture glass" & set "JW_EXPECT=%O%\GLS-1589.jpg" & call "%JW%" run 900 "%JW_GODOT%" --windowed --resolution 1280x720 --write-movie "%O%\GLS-1589.avi" --fixed-fps 30 --path "%OJ_REPO%\godot" --script res://tools/probes/plan_commit_1589_shots.gd -- --glass --out "%O%" --cam 170 --stage "PC, installed in game" > "%O%\log_glass.txt" 2>&1
if defined JW_FFMPEG if exist "%O%\GLS-1589.avi" "%JW_FFMPEG%" -y -loglevel error -i "%O%\GLS-1589.avi" -vf "fps=30,scale=1280:-2" -c:v libx264 -pix_fmt yuv420p -crf 26 -an "%O%\GLS-1589.mp4" > nul 2>&1
call "%HEAD%" tail
exit /b %ERRORLEVEL%
