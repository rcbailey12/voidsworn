@echo off
rem Issue 1279 run 3D (replaces 3C; Artoo on PR 1302: no own GitHub clone, the shared head's mirror checkout and per-arm
rem ship identity check). Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat (issue 1303).
rem The 1232 arrival bench (contrib/opus/cold_kill_1232/capture1232.gd: warm-up with only the shooter, then A16 arrives and
rem is killed 6 frames later) five times on the fix (NEW, the fix merged with main after PR 1255) and five times on that
rem main (OLD), each Godot start in the watchdog's throwaway profile, frame times solo on the GPU. The watchdog stops any
rem Godot that logs "Jolt Physics job system exceeded", so a hit is a nonzero exit.
rem PASS needs: jolt_jobs_check passes on NEW; all five NEW arrival sessions exit 0, write arrival.json, fracture, and log
rem no Jolt warning. OLD sessions are evidence only (optional steps; RUN4 hit the warning in 1 of 3 on plain main).
rem Once queued, never edited: a change ships under a new name.
setlocal EnableExtensions
set "JOB=opus1279"
set "LABEL=1279"
set "TOOLS=godot"
set "PIN_NEW=ef0c138dd22ecbe10f48433ebe07f92907bb8aab"
set "PIN_OLD=eb23594d290d1a7d7e32281b94f6545394ef2a90"

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
rem the same capture script both times, from this pin's own tree (unchanged since PR 1240)
if not exist "%OJ_REPO%\godot\bench\opus1232" mkdir "%OJ_REPO%\godot\bench\opus1232"
copy /y "%OJ_REPO%\contrib\opus\cold_kill_1232\capture1232.gd" "%OJ_REPO%\godot\bench\opus1232\capture1232.gd" > nul
if not exist "%OJ_REPO%\godot\bench\opus1232\capture1232.gd" (call "%JW%" fail "%1 capture script" & exit /b 1)
if /i "%1"=="new" (
  set "JW_STEP=new jolt_jobs_check" & set "JW_EXPECT=%O%\jolt_jobs_check.txt" & call "%JW%" run 600 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --script res://fx/test/jolt_jobs_check.gd > "%O%\jolt_jobs_check.txt" 2>&1
)
set "PC_GPU_MODE=solo"
for %%N in (1 2 3 4 5) do call :session %1 %%N
set "PC_GPU_MODE="
exit /b 0

:session
set "S=%O%\s%2"
if not exist "%S%" mkdir "%S%"
if /i "%1"=="old" set "JW_OPTIONAL=1"
if /i "%1"=="new" set "JW_EXPECT=%S%\arrival.json"
set "JW_STEP=%1 arrival s%2" & call "%JW%" run 1800 "%JW_GODOT%" --path "%OJ_REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1232/capture1232.gd -- arrival "%S%" > "%S%\log_arrival.txt" 2>&1
findstr /i /c:"job system exceeded" "%S%\log_arrival.txt" > nul 2>&1
if not errorlevel 1 (
  call "%JW%" note "%1 arrival s%2: Jolt job table warning"
  if /i "%1"=="new" (set "JW_CONTINUE=1" & call "%JW%" fail "new arrival s%2 Jolt warning")
)
if /i "%1"=="new" (
  findstr /c:"\"outcome\": \"fractured\"" "%S%\arrival.json" > nul 2>&1
  if errorlevel 1 (set "JW_CONTINUE=1" & call "%JW%" fail "new arrival s%2 did not fracture")
)
for /f "delims=" %%L in ('findstr /c:"CAPTURE1232 arrival" "%S%\log_arrival.txt" 2^>nul') do call "%JW%" note "%1 s%2 %%L"
exit /b 0
