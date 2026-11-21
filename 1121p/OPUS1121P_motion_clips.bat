@echo off
rem Motion review clips, Nov 21 2026 (thread "Check every approved battle effect is live"; Ryan: "what is in the play
rem test seems way faster and like sliding on ice than I remember"). From tools/pc/jobs/opus_job_template.bat.
rem Current main's battle code (the pin is PR 1523's head = main + one check, no motion change), the real battle scene,
rem scenario s1 (warden frigate, penitent cruiser, ascendant dreadnought, belt, seed 487), battle camera 170, Normal
rem speed, Cinematic movement, no hurry key. Six kinds per class: straight, turn, final, side, back, long (the most
rem sidesteps: a several-hex diagonal or sideways run). Fixed 30 fps so frames are true time; a frame kept every 2nd.
rem Capture script: contrib/opus/motion_1121/capture_motion.gd at the pin (run by its file path, nothing copied into godot/).
rem Outputs (out_new): <kind>\<Class>\*.jpg, <kind>\motion.json, clips\<kind>_<Class>.mp4 when ffmpeg is found.
rem Run O (after 1121N recorded nothing: the kind arrived as "OK.txt"): kind and folder also go in MOTION_KIND and
rem MOTION_OUT, the capture prints MOTION_ARGS and fails on an unknown kind or 0 frames, and each step expects the
rem Frigate's first frame.
rem Run P (after 1121O recorded straight and turn, then failed at final): only final, side, back and long. The
rem "OK.txt" kind was a typo in the bat ("%K" for "%K%" swallowed the log redirect too, so the logs are back now), and
rem final now has its own pick rule (pin 434ab1fa). Nothing on the PC is deleted. GPU: ordinary job, not a frame-time measurement.
setlocal EnableExtensions
set "JOB=opus1121motp"
set "LABEL=1523"
set "TOOLS=godot ffmpeg"
set "PIN_NEW=434ab1faee7c0d84f1a1a0e06412699a44cb5a01"
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

call :one new %PIN_NEW%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
if not exist "%O%\clips" mkdir "%O%\clips"
set "CAP=%OJ_REPO%\contrib\opus\motion_1121\capture_motion.gd"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
for %%K in (final side back long) do call :kind %%K
exit /b 0

:kind
set "K=%~1"
set "MOTION_KIND=%K%"
set "MOTION_OUT=%O%\%K%"
set "JW_STEP=capture %K%" & set "JW_EXPECT=%O%\%K%\motion.json;%O%\%K%\Frigate\00000.jpg" & call "%JW%" run 900 "%JW_GODOT%" --fixed-fps 30 --windowed --resolution 1280x720 --path "%OJ_REPO%\godot" --script "%CAP%" -- --out "%O%\%K%" --kind %K% --every 2 > "%O%\log_%K%.txt" 2>&1
if not defined JW_FFMPEG exit /b 0
for %%C in (Frigate Cruiser Dreadnought) do if exist "%O%\%K%\%%C\00000.jpg" "%JW_FFMPEG%" -y -loglevel error -framerate 15 -pattern_type sequence -start_number 0 -i "%O%\%K%\%%C\%%05d.jpg" -c:v libx264 -pix_fmt yuv420p -crf 23 "%O%\clips\%K%_%%C.mp4" > nul 2>&1
exit /b 0
