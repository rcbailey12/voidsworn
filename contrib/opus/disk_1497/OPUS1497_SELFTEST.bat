@echo off
rem Issue 1497 selftest: a PC job that passes must leave no checkout behind, and must say how much it freed.
rem Built from tools/pc/jobs/opus_job_template.bat on opus_job_head.bat. Run it only after the PR for issue 1497 has merged
rem and tools_live has been refreshed from that main (the head and its PowerShell half come from tools_live).
rem What it does, all inside its own folders (Downloads\voidsworn_test\opus1497selftest and the ship stand-in
rem opus1497selftest_ship_<time> it makes itself); nothing else on the PC is touched or deleted:
rem   1. NEW and OLD checkouts of two main commits, the ships copy into each, a real Godot import in NEW (the .import files
rem      that kept every checkout on Nov 21), and a build_info.json in both (what opus1457main1 left).
rem   2. a ship job stand-in: its own clone, a 64 MB import cache, an installed hull that matches its export and a stray file;
rem      dropcache must remove only the cache, droprepo must save the stray file and remove the clone.
rem   3. survey: a read-only list of every checkout and ship clone already on the PC, for the Board (removes nothing).
rem   4. the tail: done PASS, then NEW and OLD removed with their small files saved into out_new and out_old.
rem   5. the check: PASS only if NEW, OLD and the stand-in clone are all gone and the saved files are there. The lines that
rem      name the GB freed and C: free are copied into out_new\result.txt with the verdict.
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
findstr /c:"'droprepo'" "%OJ_PS%" > nul
if errorlevel 1 (call "%JW%" fail "tools_live's head has no issue 1497 actions; refresh tools_live from a main with PR 1497 first" & call "%HEAD%" tail & exit /b 1)

call :one new %PIN_NEW% import
if not defined JW_STOP call :one old %PIN_OLD% noimport
if not defined JW_STOP call :ship
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

rem ---- a ship job stand-in in its own new folder: dropcache, then droprepo
:ship
set "SJ=%VT%\%JOB%_ship_%OJ_STAMP%"
if exist "%SJ%" (call "%JW%" fail "ship stand-in folder already exists: %SJ%" & exit /b 1)
mkdir "%SJ%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" checkout "%SJ%" repo %PIN_NEW% >> "%OJ_ST%" 2>&1
if errorlevel 1 (call "%JW%" fail "ship stand-in clone" & exit /b 1)
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $c = Join-Path $env:SJ 'repo\godot\.godot\imported'; $null = [IO.Directory]::CreateDirectory($c); $f = [IO.File]::Create((Join-Path $c 'selftest.bin')); $f.SetLength(64MB); $f.Dispose(); $s = Join-Path $env:SJ 'repo\godot\assets\ships\SELF1497'; $e = Join-Path $env:SJ 'out\recipe\export\SELF1497'; foreach ($d in $s, $e) { $null = [IO.Directory]::CreateDirectory($d); [IO.File]::WriteAllText((Join-Path $d 'SELF1497.glb'), 'selftest hull') }; [IO.File]::WriteAllText((Join-Path $env:SJ 'repo\tools\selftest_1497_note.txt'), 'left by a stage')" >> "%OJ_ST%" 2>&1
if errorlevel 1 (call "%JW%" fail "ship stand-in files" & exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" dropcache "%SJ%" > "%OJ_OUT%\ship_dropcache.txt" 2>&1
type "%OJ_OUT%\ship_dropcache.txt" >> "%OJ_ST%"
if exist "%SJ%\repo\godot\.godot\" (call "%JW%" fail "dropcache left the stand-in's import cache" & exit /b 1)
if not exist "%SJ%\repo\.git\" (call "%JW%" fail "dropcache removed more than the import cache" & exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -File "%OJ_PS%" droprepo "%SJ%" %PIN_NEW% SELF1497 > "%OJ_OUT%\ship_droprepo.txt" 2>&1
type "%OJ_OUT%\ship_droprepo.txt" >> "%OJ_ST%"
if exist "%SJ%\repo\" (call "%JW%" fail "droprepo kept the stand-in clone, see ship_droprepo.txt" & exit /b 1)
if not exist "%SJ%\out\checkout_leftovers_repo\files\tools\selftest_1497_note.txt" (call "%JW%" fail "droprepo did not save the stray file first" & exit /b 1)
if not exist "%SJ%\out\recipe\export\SELF1497\SELF1497.glb" (call "%JW%" fail "droprepo touched the job's out folder" & exit /b 1)
>> "%OJ_ST%" echo ship stand-in: import cache removed, then the clone removed after its stray file was saved; out stays
exit /b 0

rem ---- after the tail: nothing left behind, the small files saved, the GB named
:verify
set "R=%OJ_OUT%\out_new\result.txt"
set "BAD="
if exist "%OJ_OUT%\new\" set "BAD=%BAD% new checkout still there;"
if exist "%OJ_OUT%\old\" set "BAD=%BAD% old checkout still there;"
if defined SJ if exist "%SJ%\repo\" set "BAD=%BAD% ship stand-in clone still there;"
if not exist "%OJ_OUT%\out_new\checkout_leftovers\files\godot\build_info.json" set "BAD=%BAD% new's build_info.json not saved;"
if not exist "%OJ_OUT%\out_old\checkout_leftovers\files\godot\build_info.json" set "BAD=%BAD% old's build_info.json not saved;"
findstr /c:"disk: checkouts freed" "%OJ_ST%" > nul || set "BAD=%BAD% no freed GB line;"
if not "%RC%"=="0" set "BAD=%BAD% the job itself did not pass;"
> "%R%" echo issue 1497 selftest, job %JOB%, attempt %OJ_OUT%
findstr /c:"removed after" /c:"saved " /c:"kept" /c:"disk: " /c:"done PASS" /c:"done FAILED" "%OJ_ST%" >> "%R%"
if defined BAD (>> "%R%" echo selftest FAILED:%BAD%) else (>> "%R%" echo selftest PASS: no checkout left behind)
>> "%R%" echo all done
if defined BAD set "RC=1"
exit /b 0
