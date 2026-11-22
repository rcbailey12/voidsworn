@echo off
rem Issue 1739 diagnosis C (third pass: relay_push stdin fix, stuck-Godot output): the six run_all_checks rows that fail on every Codex lane run (Windows), run one by one on the
rem fix branch with their whole output, plus which python, python3 and sh this PC's PATH gives. Code only, no GPU work:
rem nothing starts Godot or Blender except the tests' own stand-ins. Deletes nothing beyond the head's own checkout.
rem Done when: out_new holds one <test>.txt per row and tools.txt; the Board relays the attempt folder.
rem Issue 1303: the template for a helper (Opus) PC proof bat. Copy it to /mnt/project-files/board/<issue>/pc/<NAME>.bat,
rem fill the five lines marked FILL, write the steps, and send it to the Board. The Board checks only that the bat
rem calls the head (opus_job_head.bat: tools_live watchdog, exact pins, a fresh checkout or warm slot per attempt, safe ships copy with
rem the tracked-file check, throwaway Godot profiles, Ryan's options hashed before and after). Once queued, a bat is
rem never edited: a change ships under a new name.
setlocal EnableExtensions
rem ---- FILL 1: the job folder name under Downloads\voidsworn_test (letters, digits, - and _)
set "JOB=opus1739diagc"
rem ---- FILL 2: the GPU label every claim carries (the issue number)
set "LABEL=1739"
rem ---- FILL 3: tools the preflight must find: any of godot blender ffmpeg node pil
set "TOOLS=node"
rem ---- FILL 4 and 5: exact 40-character commits; OLD may be left empty for a one-commit job
set "PIN_NEW=3aa488111735e1dbbdf97bfbb5b1d64e7406c0e3"
set "PIN_OLD="
rem Issue 1659: OJ_SLOTS=1 resets a warm slot (voidsworn_test\slots) instead of a fresh clone per attempt. Off until the
rem Board turns it on after the Windows proof (Artoo on PR 1728). OJ_SLOT_KIND is gpu (slot_gpu_1 or slot_gpu_2) for
rem anything that renders, cpu (slot_cpu) for headless-only checks.
set "OJ_SLOTS=0"
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
rem ---- STEPS: which python, python3 and sh this PATH gives, then each failing row with its whole output
(where python & where python3 & where sh & python --version & python3 --version) > "%O%\tools.txt" 2>&1
pushd "%OJ_REPO%"
set "JW_STEP=picture_provenance_tests" & set "JW_OPTIONAL=1" & call "%JW%" run 600 "%JW_NODE%" contrib\opus\tools\picture_provenance_tests.js > "%O%\picture_provenance_tests.txt" 2>&1
set "JW_STEP=publish_ship_tests" & set "JW_OPTIONAL=1" & call "%JW%" run 600 "%JW_NODE%" contrib\opus\tools\publish_ship_tests.js > "%O%\publish_ship_tests.txt" 2>&1
set "JW_STEP=pysite_1535_tests" & set "JW_OPTIONAL=1" & call "%JW%" run 600 "%JW_NODE%" contrib\opus\tools\pysite_1535_tests.js > "%O%\pysite_1535_tests.txt" 2>&1
set "JW_STEP=relay_push_tests" & set "JW_OPTIONAL=1" & call "%JW%" run 600 "%JW_NODE%" contrib\opus\tools\relay_push_tests.js > "%O%\relay_push_tests.txt" 2>&1
set "JW_STEP=saved_campaign_update_tests" & set "JW_OPTIONAL=1" & call "%JW%" run 600 "%JW_NODE%" contrib\opus\tools\saved_campaign_update_tests.js > "%O%\saved_campaign_update_tests.txt" 2>&1
set "JW_STEP=stage5_fail_selftest" & set "JW_OPTIONAL=1" & call "%JW%" run 600 "%JW_NODE%" tools\recipe\stage5_fail_selftest.js > "%O%\stage5_fail_selftest.txt" 2>&1
popd
exit /b 0
