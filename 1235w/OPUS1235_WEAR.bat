@echo off
rem Issue 1235 run 2 (branch opus/issue-1235-wear): hull wear as HP falls. Look bench before (main 2533b90e) and after
rem (e06a4823): four hits on a Sunward V16_37, Glasswright I15_11 and Chorus B21_11 cruiser, then hull HP set to 55%
rem (wear) and 22% (full wear and the crippled list), at camera 170 and 26. Rows: godot/bench/look_moments_wear.json.
rem Main's look bench has no "pre" and "sync_t" row keys, so after the old checkout's ships step (which checks tracked
rem files) the branch's bench/look_bench.gd (harness only, about 15 added lines) and the rows file are copied into it. Game
rem code in the before run is main's own. Built from tools/pc/jobs/opus_job_template.bat.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1235w"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1235"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=e06a4823bbb6f9f0476a057030bbae6279849a9b"
set "PIN_OLD=2533b90e547b67567f456aad8827601e14c8b9ff"

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

call :one new %PIN_NEW%
if defined PIN_OLD call :one old %PIN_OLD%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships, import, then the job's own steps. Every Godot start goes through job_wrap.
:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
set "JW_STEP=%1 import" & call "%JW%" run 1800 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1
rem ---- STEPS: the hull wear look bench rows, 1080p, fixed 60 fps (the head sets the throwaway profile)
if /i "%1"=="new" set "ROWS=%OJ_REPO%\godot\bench\look_moments_wear.json"
if /i "%1"=="new" set "BENCH=%OJ_REPO%\godot\bench\look_bench.gd"
if /i "%1"=="old" if defined ROWS copy /y "%ROWS%" "%OJ_REPO%\godot\bench\look_moments_wear.json" > nul
if /i "%1"=="old" if defined BENCH copy /y "%BENCH%" "%OJ_REPO%\godot\bench\look_bench.gd" > nul
if not exist "%OJ_REPO%\godot\bench\look_moments_wear.json" (call "%JW%" fail "%1 rows file missing" & exit /b 1)
findstr /c:"sync_t" "%OJ_REPO%\godot\bench\look_bench.gd" > nul || (call "%JW%" fail "%1 look bench has no sync_t rows" & exit /b 1)
set "JW_STEP=%1 wear bench" & set "JW_EXPECT=%O%\moments" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%" --part moments --moments res://bench/look_moments_wear.json > "%O%\bench_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "%1 bench did not finish (see %O%\bench_log.txt)"
exit /b 0
