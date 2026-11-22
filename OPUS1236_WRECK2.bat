@echo off
rem Issue 1236 wrecks, WRECK2 (WRECK1 stalled 25 min on the Navy dreadnought row, no log). (Ryan, Nov 22: big ships play their death and then shrink, it looks bad; his picks on two cards:
rem "ends crumble away", then "keep it, let it poke out"). Look-bench before/after sheet plus a clip with sound of six big
rem deaths anchored to a hex (rest radius 8, as the game): Navy cruiser and dreadnought, Sunward cruiser, Hullbreaker
rem battle-barge, Glasswright cruiser, Chorus bio-titan, to 8 s after the split at cameras 170 and 60. Before is 09ed8d0c
rem (main 2c2e0e3f plus only the bench's "hex" key, its WRECK2 logs and godot/bench/look_moments_1236.json, the dreadnought
rem row first: the wreck shrinks to fit); after is 4b4e2fe4 (work/issue-1236-crumble 674e8b92 plus the same two bench files: nothing shrinks, the biggest
rem piece stays at real size and centred, the rest crumble). Both reachable from branch claude/project-thread-q7nudv.
rem Writes out_new and out_old: moments strips, WRK-1236.avi and WRK-1236.mp4 (when ffmpeg is found). GPU: ordinary job,
rem no frame-time step. Nothing on the PC is deleted. Built from tools/pc/jobs/opus_job_template.bat (the
rem OPUS1587_WOUNDS4 layout).
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1236x"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1236"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot ffmpeg"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=4b4e2fe4b553310759c672c4c1daf6fb652a1a36"
set "PIN_OLD=09ed8d0c9c7e26092a6e54b9cb7405aed5172295"

rem The head is the installed main copy in tools_live (fail closed). OPUS_JOB_HEAD may name another copy only for a
rem pre-merge smoke, together with OPUS_JOB_HEAD_PREMERGE=1; the head logs that.
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

rem WRECK2: the old pin first, so a stall on the dreadnought row in both pins shows it is not the crumble code
if defined PIN_OLD call :one old %PIN_OLD%
call :one new %PIN_NEW%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships, import, then the job's own steps. Every Godot start goes through job_wrap.
:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
rem ---- STEPS (issue 1236). The game as it ships, no option switches.
rem A: the look bench rows at 1080p, fixed 60 fps, with the death sounds and the bench picture in the window, recorded
if not exist "%OJ_REPO%\godot\bench\look_moments_1236.json" (call "%JW%" fail "%1 rows file missing" & exit /b 1)
set "JW_STEP=%1 bench" & set "JW_EXPECT=%O%\moments" & call "%JW%" run 3600 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --write-movie "%O%\WRK-1236.avi" res://bench/look_bench.tscn -- --out "%O%" --part moments --sound --moments res://bench/look_moments_1236.json > "%O%\bench_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "%1 bench did not finish (see %O%\bench_log.txt)"
rem B: the clip as mp4 (picture and sound), 1280 wide
if defined JW_FFMPEG if exist "%O%\WRK-1236.avi" "%JW_FFMPEG%" -y -loglevel error -i "%O%\WRK-1236.avi" -vf "scale=1280:-2" -c:v libx264 -pix_fmt yuv420p -crf 26 -c:a aac -b:a 128k "%O%\WRK-1236.mp4" > nul 2>&1
exit /b 0
