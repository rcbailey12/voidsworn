@echo off
rem Issue 1582 run A: movement stage 2 captures on the PC's installed hulls. Branch opus/issue-1582 at PIN_NEW.
rem From tools/pc/jobs/opus_job_template.bat and board/1581/pc/OPUS1581B_motion_clips.bat.
rem Two parts: (1) contrib/opus/tools/issue1582/stage2_shots.gd --real --clips (copied out of the checkout to the job
rem folder, run by its file path; nothing copied into godot/): camera 170, a low orbit, a selected drop-line, the strike
rem craft dive strip and frames, the six faction jets sheet, and a 240-frame camera orbit; (2) the real battle scene's
rem fixed screenshot moments (--shots, seed 4242, belt) for the bands among real terrain and mid-battle fire.
rem Outputs: shots\*.jpg, shots\clip_orbit\*.jpg, shots\clip_dive\*.jpg, battle\*.png, clips\orbit.mp4 and clips\dive.mp4
rem when ffmpeg is found. Nothing on the PC is deleted. GPU: ordinary job, not a frame-time measurement.
setlocal EnableExtensions
set "JOB=opus1582d"
set "LABEL=1582"
set "TOOLS=godot ffmpeg"
set "PIN_NEW=ad7dfa6bc9b1449259fc5ba0a170042873342139"

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
set "CAP=%OJ_OUT%\stage2_shots.gd"
copy /y "%OJ_REPO%\contrib\opus\tools\issue1582\stage2_shots.gd" "%CAP%" > nul
set "S=%OJ_OUT%\shots"
set "B=%OJ_OUT%\battle"
if not exist "%S%" mkdir "%S%"
if not exist "%B%" mkdir "%B%"
if not exist "%OJ_OUT%\clips" mkdir "%OJ_OUT%\clips"
set "JW_STEP=import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%OJ_OUT%\import.txt" 2>&1
set "JW_STEP=stage2 shots" & set "JW_EXPECT=%S%\ST2_e_faction_jets.jpg" & call "%JW%" run 1200 "%JW_GODOT%" --fixed-fps 30 --windowed --resolution 1280x720 --path "%OJ_REPO%\godot" --script "%CAP%" -- "%S%" --real --clips > "%OJ_OUT%\log_shots.txt" 2>&1
set "JW_EXPECT="
set "JW_STEP=battle shots" & call "%JW%" run 1200 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --resolution 1920x1080 -- --seed 4242 --fac hegemony --map belt --shots "%B%" --quit-after 900 > "%OJ_OUT%\log_battle.txt" 2>&1
if defined JW_FFMPEG (
  if exist "%S%\clip_orbit\00000.jpg" "%JW_FFMPEG%" -y -loglevel error -framerate 30 -pattern_type sequence -start_number 0 -i "%S%\clip_orbit\%%05d.jpg" -c:v libx264 -pix_fmt yuv420p -crf 23 "%OJ_OUT%\clips\orbit.mp4" > nul 2>&1
  if exist "%S%\clip_dive\00000.jpg" "%JW_FFMPEG%" -y -loglevel error -framerate 30 -pattern_type sequence -start_number 0 -i "%S%\clip_dive\%%05d.jpg" -c:v libx264 -pix_fmt yuv420p -crf 23 "%OJ_OUT%\clips\dive.mp4" > nul 2>&1
)
call "%HEAD%" tail
exit /b %ERRORLEVEL%
