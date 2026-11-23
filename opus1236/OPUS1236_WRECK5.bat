@echo off
rem Issue 1236 wrecks, WRECK5 (round 4). Ryan, Nov 23, on the WRECK4 clip: the broken section "melds into the hull
rem wreckage piece", "every ship is breaking at the same spot"; he wants three pieces spread across the hex and more than
rem one kind of death. Round 4: the first crack follows the last hit; big hulls break in three; three breakups (two, three,
rem late snap). Look-bench before/after sheet plus a clip with sound: Navy dreadnought, Navy cruiser and Sunward cruiser,
rem each killed three ways after a hit at the stern, amidships or the bow, anchored to a hex (rest radius 8), to 8 s after
rem the split at camera 170 and the close camera 26. Before is 830455f0 (WRECK4's after 6ce553cb plus only the new rows
rem file); after is a69c7a1d (work/issue-1236-crumble e26dab6c plus the bench keys breakup and hit and the same rows file).
rem Both reachable from branch claude/project-thread-q7nudv. Writes out_new and out_old: moments strips, WRK-1236.avi and
rem WRK-1236.mp4 (when ffmpeg is found). GPU: ordinary job, no frame-time step. Nothing on the PC is deleted. Built from
rem tools/pc/jobs/opus_job_template.bat (the OPUS1587_WOUNDS4 layout).
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1236r5"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1236"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot ffmpeg"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=a69c7a1de1304013594d24e9fb1eb382bb687204"
set "PIN_OLD=830455f0e6f7a8c677d39bcd686a94dc5207c9ee"

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

rem The old pin first, as WRECK4
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
if not exist "%OJ_REPO%\godot\bench\look_moments_1236r4.json" (call "%JW%" fail "%1 rows file missing" & exit /b 1)
set "JW_STEP=%1 bench" & set "JW_EXPECT=%O%\moments" & call "%JW%" run 3600 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --write-movie "%O%\WRK-1236.avi" res://bench/look_bench.tscn -- --out "%O%" --part moments --sound --moments res://bench/look_moments_1236r4.json > "%O%\bench_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "%1 bench did not finish (see %O%\bench_log.txt)"
rem B: the clip as mp4 (picture and sound), 1280 wide
if defined JW_FFMPEG if exist "%O%\WRK-1236.avi" "%JW_FFMPEG%" -y -loglevel error -i "%O%\WRK-1236.avi" -vf "scale=1280:-2" -c:v libx264 -pix_fmt yuv420p -crf 26 -c:a aac -b:a 128k "%O%\WRK-1236.mp4" > nul 2>&1
exit /b 0
