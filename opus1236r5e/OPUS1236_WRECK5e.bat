@echo off
rem Issue 1236 wrecks, WRECK5e: the after side of WRECK5d only. WRECK5d's before side (637addf8) ran past its 3600 s
rem ceiling on its last row while the GPU line was shared, so its after side never ran. The before pictures are
rem WRECK5c's (the same pin 637addf8 and the same rows file, which passed), so this job runs only the after pin
rem 5a7da394 (work/issue-1236-crumble dbc79f32 plus the bench commits, reachable from branch
rem claude/project-thread-q7nudv) with a 7200 s bench ceiling (WRECK5c's after side took 51 minutes alone).
rem The fix being filmed: every big metal hull is cut on two joints leaving no piece under 0.15 of its length (authored
rem joints first, else a plain joint added clear of machines), and a long hull's pieces stay within the hex. Ryan,
rem Nov 23: three pieces spread across the hex, the break near the hit, more than one kind of death. Rows: Navy
rem dreadnought, Navy cruiser and Sunward cruiser, each killed three ways after a hit at the stern, amidships or the
rem bow, anchored to a hex (rest radius 8), to 8 s after the split at camera 170 and the close camera 26, plus one
rem cruiser killed by a later hit at the other end. Writes out_new: moments strips, WRK-1236.avi and WRK-1236.mp4
rem (when ffmpeg is found). GPU: ordinary job, no frame-time step. Nothing on the PC is deleted. Built from
rem tools/pc/jobs/opus_job_template.bat (the OPUS1587_WOUNDS4 layout).
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1236r5e"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1236"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot ffmpeg"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=5a7da3947e424691f21783546816cce01d64ea65"
set "PIN_OLD="

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

rem One pin only: the before side is WRECK5c's
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
set "JW_STEP=%1 bench" & set "JW_EXPECT=%O%\moments" & call "%JW%" run 7200 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --write-movie "%O%\WRK-1236.avi" res://bench/look_bench.tscn -- --out "%O%" --part moments --sound --moments res://bench/look_moments_1236r4.json > "%O%\bench_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "%1 bench did not finish (see %O%\bench_log.txt)"
rem B: the clip as mp4 (picture and sound), 1280 wide
if defined JW_FFMPEG if exist "%O%\WRK-1236.avi" "%JW_FFMPEG%" -y -loglevel error -i "%O%\WRK-1236.avi" -vf "scale=1280:-2" -c:v libx264 -pix_fmt yuv420p -crf 26 -c:a aac -b:a 128k "%O%\WRK-1236.mp4" > nul 2>&1
exit /b 0
