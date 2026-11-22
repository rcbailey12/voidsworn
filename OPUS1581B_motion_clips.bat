@echo off
rem Issue 1581 run B: the same clips after the OpenAI review fixes (PR 1591 at the new pin; run A was 58441d7d). Burn and fire now records the first muzzle against the stop (shot_after_stop_s). From tools/pc/jobs/opus_job_template.bat
rem and the Nov 21 motion bats (board/motion_1121/pc/OPUS1121P_motion_clips.bat).
rem Real battle scene, scenario s1 (warden frigate, penitent cruiser, ascendant dreadnought, belt, seed 487), battle camera
rem 170, Normal speed, Cinematic movement, no hurry key, fixed 30 fps (frames are true time), a frame kept every 2nd.
rem Kinds per class: straight, turn, final, side, back, long, over (a pass over a rock or under an enemy hull) and burn_fire
rem (a Burn and fire on an enemy set down 6 to 12 hexes ahead; capture only). NEW is the opus/issue-1581 commit, OLD is
rem main 1a000813 (the Nov 21 behaviour, before). Both run the NEW capture script (copied out of the NEW checkout to the
rem job folder, run by its file path; nothing copied into godot/). On main the 1581 telemetry fields read 0.
rem Outputs: out_new and out_old: <kind>\<Class>\*.jpg, <kind>\motion.json, clips\<kind>_<Class>.mp4; pairs\<kind>_<Class>.mp4
rem (before left, after right) when ffmpeg is found. Nothing on the PC is deleted. GPU: ordinary job, not a frame-time measurement.
setlocal EnableExtensions
set "JOB=opus1581b"
set "LABEL=1581"
set "TOOLS=godot ffmpeg"
set "PIN_NEW=bdde116ca0823b55ec29f45ed60958243ae77b35"
set "PIN_OLD=1a000813476a855163b5cd76af627198097a405b"

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

set "CAP=%OJ_OUT%\capture_1581.gd"
call :one new %PIN_NEW%
call :one old %PIN_OLD%
call :pairs
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
if "%1"=="new" copy /y "%OJ_REPO%\contrib\opus\motion_1581\capture_motion.gd" "%CAP%" > nul
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
if not exist "%O%\clips" mkdir "%O%\clips"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
for %%K in (straight turn final side back long over burn_fire) do call :kind %1 %%K
exit /b 0

:kind
set "K=%~2"
set "MOTION_KIND=%K%"
set "MOTION_OUT=%O%\%K%"
set "JW_STEP=%1 capture %K%" & set "JW_EXPECT=%O%\%K%\motion.json" & call "%JW%" run 900 "%JW_GODOT%" --fixed-fps 30 --windowed --resolution 1280x720 --path "%OJ_REPO%\godot" --script "%CAP%" -- --out "%O%\%K%" --kind %K% --every 2 > "%O%\log_%K%.txt" 2>&1
if not defined JW_FFMPEG exit /b 0
for %%C in (Frigate Cruiser Dreadnought) do if exist "%O%\%K%\%%C\00000.jpg" "%JW_FFMPEG%" -y -loglevel error -framerate 15 -pattern_type sequence -start_number 0 -i "%O%\%K%\%%C\%%05d.jpg" -c:v libx264 -pix_fmt yuv420p -crf 23 "%O%\clips\%K%_%%C.mp4" > nul 2>&1
exit /b 0

:pairs
if not defined JW_FFMPEG exit /b 0
if not exist "%OJ_OUT%\pairs" mkdir "%OJ_OUT%\pairs"
for %%K in (straight turn final side back long over burn_fire) do for %%C in (Frigate Cruiser Dreadnought) do if exist "%OJ_OUT%\out_old\clips\%%K_%%C.mp4" if exist "%OJ_OUT%\out_new\clips\%%K_%%C.mp4" "%JW_FFMPEG%" -y -loglevel error -i "%OJ_OUT%\out_old\clips\%%K_%%C.mp4" -i "%OJ_OUT%\out_new\clips\%%K_%%C.mp4" -filter_complex "[0:v]tpad=stop_mode=clone:stop_duration=6[a];[1:v]tpad=stop_mode=clone:stop_duration=6[b];[a][b]hstack=inputs=2:shortest=1,scale=1280:-2" -c:v libx264 -pix_fmt yuv420p -crf 24 "%OJ_OUT%\pairs\%%K_%%C.mp4" > nul 2>&1
exit /b 0
