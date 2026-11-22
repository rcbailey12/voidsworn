@echo off
rem Issue 1589 run D (after Ryan's Nov 22 look: the card hides while the event plays, the drawn cone runs around edge hexes, the open plan names its keys on the card; plus the Glasswright clip the outside review asked for): plan-then-commit turns (PR 1643). From board/1581/pc/OPUS1581B_motion_clips.bat (same windowed movie pattern).
rem Real battle scene, scenario s1 seed 1001; two enemies are set a few hexes ahead of the first ready ship. Battle camera 170,
rem Normal speed. The probe (godot/tools/probes/plan_commit_1589_shots.gd, run from the pinned checkout) writes
rem PLN-1589_plan.jpg (ghost plus two picks plus the card), PLN-1589_commit.jpg (move and volley as one event) and
rem PLN-1589_steps.jpg (Backspace, turn, Backspace, pick again) and ENY-1589.jpg (the next enemy activation), and Godot's movie writer records the whole run as PLN-1589.avi; ffmpeg makes
rem PLN-1589.mp4 (under 10 MB) when found. A second run (--glass, a Glasswright fleet) writes GLS-1589.jpg (the shot, the commit,
rem the move left after firing as a ghost, that move playing) and GLS-1589.avi/.mp4. Only the new pin runs (no before).
rem Nothing on the PC is deleted. GPU: ordinary job.
setlocal EnableExtensions
set "JOB=opus1589d"
set "LABEL=1589"
set "TOOLS=godot ffmpeg"
set "PIN_NEW=3fdffcd6e3b101e697a122820ca99ebe37eb1054"

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
