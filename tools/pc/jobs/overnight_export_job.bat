@echo off
rem Issue 1663 (Ryan, Nov 22 2026, owner decision 4): the overnight build\export refresh. overnight_export.ps1 queues a
rem small bat that sets ON_PIN (main's full commit) and ON_DATE (its git %cI date) and calls this from tools_live. It runs
rem through the job head like any helper job: checks out main (a warm cpu slot once issue 1659 is in, else a fresh
rem checkout), copies the built ships from build\godot, stamps build_info.json, then runs g2_export.bat from build\ on that
rem checkout, so the existing candidate, export check, 2-battle smoke and promotion into build\export are unchanged.
rem G2_PROMOTE_ONLY_IDLE=1 makes g2_export refuse to replace build\export while Voidsworn is running (Ryan playing).
rem A pass records the commit in voidsworn_test\overnight_export\state.txt. build\godot itself is never changed.
rem Built from opus_job_template.bat (issue 1303). Once queued, a bat is never edited: a change ships under a new name.
setlocal EnableExtensions
set "ON_HERE=%~dp0"
if not defined ON_PIN (echo FAILED: no ON_PIN; overnight_export.ps1 queues this job & exit /b 2)
if not defined ON_DATE (echo FAILED: no ON_DATE & exit /b 2)
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1663night"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1663"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=godot"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=%ON_PIN%"
set "PIN_OLD="
rem Issue 1659: a warm cpu slot (voidsworn_test\slots\slot_cpu) instead of a fresh checkout each night, once that is in.
set "OJ_SLOTS=1"
set "OJ_SLOT_KIND=cpu"

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
if defined JW_STOP (>> "%OJ_ST%" echo skipped the export: an earlier step failed & exit /b 1)
rem ---- STEPS: build provenance, then the existing export, check, smoke and promotion from build\ on this checkout
pushd "%OJ_REPO%"
call "%OJ_REPO%\tools\pc\jobs\g2_playtest_capture.bat" prepare %ON_PIN% %ON_DATE% > "%O%\prepare.txt" 2>&1
set "ON_RC=%ERRORLEVEL%"
popd
if not "%ON_RC%"=="0" (call "%JW%" fail "build_info.json stamp, see %O%\prepare.txt" & exit /b 1)
set "G2_PROMOTE_ONLY_IDLE=1"
pushd "%VT%\build"
call "%ON_HERE%g2_export.bat" "%OJ_REPO%\godot" > "%O%\export_call.txt" 2>&1
set "ON_RC=%ERRORLEVEL%"
popd
if exist "%VT%\shots\g2_export_log.txt" copy /y "%VT%\shots\g2_export_log.txt" "%O%\g2_export_log.txt" > nul
if not "%ON_RC%"=="0" (call "%JW%" fail "g2_export, see %O%\g2_export_log.txt" & exit /b 1)
if not exist "%VT%\overnight_export" mkdir "%VT%\overnight_export"
powershell -NoProfile -Command "$f = Join-Path $env:VT 'overnight_export\state.txt'; $l = @(); if (Test-Path -LiteralPath $f) { $l = @([IO.File]::ReadAllLines($f) | Where-Object { $_ -notlike 'exported *' }) }; [IO.File]::WriteAllLines($f, [string[]]($l + ('exported ' + $env:ON_PIN)))" >> "%OJ_ST%" 2>&1
>> "%OJ_ST%" echo overnight export: build\export now built from %ON_PIN%
exit /b 0
