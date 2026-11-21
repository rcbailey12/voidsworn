@echo off
rem Issue 1235 (PR 1245): ships look damaged from the first hit. Look bench before (main 624796c5) and after (PR head
rem 721d4f88, main merged in): one torpedo on a fresh Sunward V16_37, Glasswright I15_11 and Chorus B21_11 cruiser, and
rem every section at stage 4, at camera 170 and 26. Rows: godot/bench/look_moments_first_hit.json from the new pin (main
rem has no such file, so it is copied into the old checkout after its ships step; it is untracked there).
rem Built from tools/pc/jobs/opus_job_template.bat (issue 1303). Replaces shots1235.bat of Nov 19, which never ran.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1235"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1235"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=721d4f880bc7ee91202d50131666dc3bd596efc2"
set "PIN_OLD=624796c5ace0128da645956eeed571e20d954e61"

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
rem ---- STEPS: the first-hit look bench rows, 1080p, fixed 60 fps (the head sets the throwaway profile)
if /i "%1"=="new" set "ROWS=%OJ_REPO%\godot\bench\look_moments_first_hit.json"
if /i "%1"=="old" if defined ROWS copy /y "%ROWS%" "%OJ_REPO%\godot\bench\look_moments_first_hit.json" > nul
if not exist "%OJ_REPO%\godot\bench\look_moments_first_hit.json" (call "%JW%" fail "%1 rows file missing" & exit /b 1)
set "JW_STEP=%1 first-hit bench" & set "JW_EXPECT=%O%\moments" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%" --part moments --moments res://bench/look_moments_first_hit.json > "%O%\bench_log.txt" 2>&1
findstr /c:"LOOK_BENCH_DONE" "%O%\bench_log.txt" > nul || call "%JW%" fail "%1 bench did not finish (see %O%\bench_log.txt)"
exit /b 0
