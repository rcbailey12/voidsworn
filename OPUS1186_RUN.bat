@echo off
rem OPUS1186_RUN (issue 1186, PR 1334): Windows runner tests for one reused checkout per arm and the inherited slot lock.
rem Built from the issue 1303 template for a helper (Opus) PC proof bat. Copy it to /mnt/project-files/board/<issue>/pc/<NAME>.bat,
rem fill the five lines marked FILL, write the steps, and send it to the Board. The Board checks only that the bat
rem calls the head (opus_job_head.bat: tools_live watchdog, exact pins, fresh checkout per attempt, safe ships copy with
rem the tracked-file check, throwaway Godot profiles, Ryan's options hashed before and after). Once queued, a bat is
rem never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1186"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1186"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=node"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=e11b41f7fba62ab9a22e873033b1a65e153b828b"
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

call :one new %PIN_NEW%
if defined PIN_OLD call :one old %PIN_OLD%
call "%HEAD%" tail
exit /b %ERRORLEVEL%

rem ---- one pinned commit: checkout, ships, import, then the job's own steps. Every Godot start goes through job_wrap.
:one
call "%HEAD%" checkout %1 %2
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
rem Issue 1186 (PR 1334): the Windows runner tests at the pin. Code only, no GPU, no ships. Nothing outside the job folder is
rem changed; every fixture lives in TEMP and each test removes its own evidence after a PASS.
set "NODE22=%VT%\node\node.exe"
pushd "%OJ_REPO%"
set "JW_STEP=%1 runner selftest" & set "JW_EXPECT=%O%\runner_selftest.txt" & call "%JW%" run 1800 "%NODE22%" tools\pc\runner_selftest.js > "%O%\runner_selftest.txt" 2>&1
set "JW_STEP=%1 runner job tests" & set "JW_EXPECT=%O%\runner_job_tests.txt" & call "%JW%" run 900 "%NODE22%" contrib\opus\tools\runner_job_tests.js > "%O%\runner_job_tests.txt" 2>&1
set "JW_STEP=%1 runner cleanup tests" & set "JW_EXPECT=%O%\runner_cleanup_tests.txt" & call "%JW%" run 900 "%NODE22%" contrib\opus\tools\runner_cleanup_tests.js > "%O%\runner_cleanup_tests.txt" 2>&1
set "JW_STEP=%1 report paths tests" & set "JW_EXPECT=%O%\report_paths_tests.txt" & call "%JW%" run 600 "%NODE22%" contrib\opus\tools\report_paths_tests.js > "%O%\report_paths_tests.txt" 2>&1
set "JW_STEP=%1 lane refresh selftest" & set "JW_EXPECT=%O%\lane_refresh.txt" & call "%JW%" run 600 "%NODE22%" tools\pc\lane_tools_refresh_selftest.js > "%O%\lane_refresh.txt" 2>&1
set "JW_STEP=%1 pause selftest" & set "JW_EXPECT=%O%\pause_all.txt" & call "%JW%" run 600 "%NODE22%" tools\pc\pause_all_selftest.js > "%O%\pause_all.txt" 2>&1
rem Read only: today's per-run Workhorse copies (the "before" disk cost). Nothing is removed.
set "JW_STEP=%1 workhorse sizes" & set "JW_OPTIONAL=1" & set "JW_EXPECT=%O%\work217_sizes.txt" & call "%JW%" run 600 powershell.exe -NoProfile -Command "$w=Join-Path $env:USERPROFILE 'Downloads\voidsworn_test\work217'; Get-ChildItem -LiteralPath $w -Directory -Filter 'issue-*' -ErrorAction SilentlyContinue | ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Directory } | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'repo') } | ForEach-Object { $b=(Get-ChildItem -LiteralPath (Join-Path $_.FullName 'repo') -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum; '{0:N2} GiB {1}' -f ($b/1GB), $_.FullName }; 'done'" > "%O%\work217_sizes.txt" 2>&1
popd
exit /b 0
