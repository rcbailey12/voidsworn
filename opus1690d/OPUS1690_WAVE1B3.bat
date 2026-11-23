@echo off
rem Issue 1691 (Wave 1B, PR 1736, R412 with R402), replacing WAVE1B2 (its rows were Wave 1A's and its pins were not
rem like-for-like): target-material impacts and the metal-only wear gate, look-bench before/after sheet. Before is
rem 26a1205e (main 2fc06136, the commit just before the 1736 merge, plus only godot/bench/look_moments_1691.json); after
rem is 69de9b56 (the 1736 merge 54936d6d plus the same file, nothing else). Both reachable from branch
rem claude/project-thread-lnk6bv. Rows (cameras 170 and 26): a heavy battery shell, torpedo, gauss slug, lance and a
rem critical hit on a Sunward (metal reference), Glasswright, Chorus and Eclipse cruiser, then a worn Sunward,
rem Glasswright and Chorus hull at 30% after four hits. No frame-time step (WAVE1B2's ran with vsync on).
rem Both pins are merged main commits, so the bench's "installed in game" stamp is accurate here.
rem Built from tools/pc/jobs/opus_job_template.bat (the OPUS1690_WAVE1B layout, bench step only).
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1690d"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1691"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=69de9b56e2ec67b3a909bfc95b0cb282a0824230"
set "PIN_OLD=26a1205ef8d9069e3df453aa1698f82dd93f311c"
rem Issue 1659: warm slots on, gpu kind (this job renders).
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=gpu"

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
rem ---- STEPS (issue 1691). The game as it ships, no option switches (VS_WOUNDS_V2 not set).
rem A: the look bench rows, 1080p, fixed 60 fps (the head sets the throwaway profile)
if not exist "%OJ_REPO%\godot\bench\look_moments_1691.json" (call "%JW%" fail "%1 rows file missing" & exit /b 1)
set "JW_STEP=%1 bench" & set "JW_EXPECT=%O%\moments" & call "%JW%" run 2400 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%" --part moments --moments res://bench/look_moments_1691.json > "%O%\bench_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "%1 bench did not finish (see %O%\bench_log.txt)"
exit /b 0
