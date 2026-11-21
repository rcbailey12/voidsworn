@echo off
rem Issue 1497 selftest: a PC job that passes must leave no checkout behind, and must say how much it freed.
rem Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat. Run it only after the PR for issue 1497 has merged
rem and tools_live has been refreshed from that main (the head and its PowerShell half come from tools_live).
rem Part 1 of 2. Part 2 is OPUS1497_AFTERRELAY.bat, which the Board runs right after relaying this job's out_new and
rem out_old folders (every file in them) to a board/pc-out branch. Checkouts go only after that relay (Artoo on PR 1498).
rem What part 1 does, all inside its own folder Downloads\voidsworn_test\opus1497selftest; nothing else is touched:
rem   1. NEW and OLD checkouts of two main commits, the ships copy into each (with its copy-time record), a real Godot
rem      import in NEW (the .import files that kept every checkout on Nov 21), and a build_info.json in both (what
rem      opus1457main1 left).
rem   2. survey: a read-only list of every checkout and ship clone already on the PC, for the Board (removes nothing).
rem   3. the tail: done PASS, then the checkout step, which must keep NEW and OLD because nothing is relayed yet.
rem   4. the check: PASS only if the job passed, both checkouts are still there, the tail said they wait for the relay,
rem      and both ships records exist. out_new\result.txt says so.
rem Once queued, never edited; a change ships under a new name (next: OPUS1497_SELFTEST2.bat).
setlocal EnableExtensions
set "JOB=opus1497selftest"
set "LABEL=1497"
set "TOOLS=godot"
set "PIN_NEW=b683f7afa5f699ed04e3accf1784d71a45a619d0"
set "PIN_OLD=e246a1bb51837f1b6a35a08cf0a801fb9163a4fb"

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
rem the head this job runs must have the issue 1497 actions
findstr /c:"Assert-Relayed" "%OJ_PS%" > nul
if errorlevel 1 (call "%JW%" fail "tools_live's head has no issue 1497 actions; refresh tools_live from a main with PR 1497 first" & call "%HEAD%" tail & exit /b 1)

call :one new %PIN_NEW% import
if not defined JW_STOP call :one old %PIN_OLD% noimport
if not defined JW_STOP (
  > "%OJ_OUT%\out_new\survey.txt" powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" survey 2>&1
  >> "%OJ_ST%" echo survey of the PC's checkouts written to out_new\survey.txt ^(read only^)
)
call "%HEAD%" tail
set "RC=%ERRORLEVEL%"
call :verify
exit /b %RC%

rem ---- one pinned commit: checkout, ships, (import), and the small file real jobs leave behind
:one
call "%HEAD%" checkout %1 %2
call "%HEAD%" ships
set "O=%OJ_OUT%\out_%1"
if not exist "%O%" mkdir "%O%"
if defined JW_STOP exit /b 0
if /i "%3"=="import" (set "JW_STEP=%1 import" & set "JW_EXPECT=%O%\import.txt" & call "%JW%" run 2400 "%JW_GODOT%" --headless --path "%OJ_REPO%\godot" --import > "%O%\import.txt" 2>&1)
if defined JW_STOP exit /b 0
> "%OJ_REPO%\godot\build_info.json" echo {"commit": "%2", "selftest": 1497}
if not exist "%OJ_REPO%\godot\build_info.json" (call "%JW%" fail "could not write build_info.json in %1" & exit /b 1)
>> "%OJ_ST%" echo %1: build_info.json written inside the checkout, as the player path jobs do
exit /b 0

rem ---- after the tail: nothing removed before the relay, the records written
:verify
set "R=%OJ_OUT%\out_new\result.txt"
set "BAD="
if not exist "%OJ_OUT%\new\.git\" set "BAD=%BAD% new checkout gone before the relay;"
if not exist "%OJ_OUT%\old\.git\" set "BAD=%BAD% old checkout gone before the relay;"
if not exist "%OJ_OUT%\new_ships_copied.txt" set "BAD=%BAD% no ships record for new;"
if not exist "%OJ_OUT%\old_ships_copied.txt" set "BAD=%BAD% no ships record for old;"
findstr /c:"results not relayed yet" "%OJ_ST%" > nul || set "BAD=%BAD% the tail did not wait for the relay;"
if not "%RC%"=="0" set "BAD=%BAD% the job itself did not pass;"
> "%R%" echo issue 1497 selftest part 1, job %JOB%, attempt %OJ_OUT%
findstr /c:"ships copy recorded" /c:"kept" /c:"disk: " /c:"done PASS" /c:"done FAILED" "%OJ_ST%" >> "%R%"
if defined BAD (>> "%R%" echo selftest part 1 FAILED:%BAD%) else (>> "%R%" echo selftest part 1 PASS: checkouts wait for the relay; relay out_new and out_old, then run OPUS1497_AFTERRELAY.bat)
>> "%R%" echo all done
if defined BAD set "RC=1"
exit /b 0
