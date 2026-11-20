@echo off
title Opus 1180: install 2, main's tools as tools_live after PR 1284 (no idle wait, deletes nothing)
rem Issue 1180 rollout, install 2 (Board, Nov 20), after PR 1284 merged: the first install staged a version but could not
rem switch current.txt (File.Replace got "" for its backup path). This runs main's FIXED refresh from its own clone, so it is
rem the one-time bootstrap: the watcher and job_wrap prefer the refresh inside the current (old) tools_live, which still
rem has the bug, until current.txt names a fixed version. The staged 72366b168801 is not the target (PR 1284 changed the
rem tools tree); it stays as an unused verified version for the rotation rule.
rem Installs origin/main's tools as a new Downloads\voidsworn_test\tools_live\<version>\ next to the current one through
rem main's own lane_tools_refresh.ps1 -Build tools_live (stage, verify every file, write hashes.txt, then flip current.txt in
rem one rename). Running jobs keep the version they already resolved; only jobs that start afterwards use the new one.
rem It does not wait for an idle GPU: 1180 changed run_timeout.ps1 only in how it removes its own Godot profile, and
rem gpu_slots.js is unchanged, so old and new watchdogs share one claim protocol.
rem It deletes nothing: the refresh rotates out a version only when more than four exist and its replacement is over a day
rem old, so this stops before the install when four or more exist and any is over a day old, and fails if the log
rem shows a rotation.
rem It refuses while a job is starting: a starting job holds lane_tools_refresh.lock while it refreshes; this waits up to
rem 5 minutes for that lock to be free, then stops.
rem Checks after the install: the 1180 files are present, the strict hash check passes, and a step through an old copy
rem of tmo.bat hands off to the new tools_live watchdog. Last, PC_DOCTOR (read only).
rem Then an ordinary job_wrap init must resolve the new version, and the janitor runs --dry-run (removes nothing).
rem Log: opus1180\tools_install2_<A>\result.txt, PASSED or FAILED, then all done.
setlocal EnableDelayedExpansion
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1180
set C=%W%\main
set TL=%V%\tools_live
if not exist "%W%" mkdir "%W%"
set A=1
:findattempt
if exist "%W%\tools_install2_%A%" (set /a A+=1 & goto findattempt)
set O=%W%\tools_install2_%A%
mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% attempt %A% > "%RES%"
if exist "%V%\node\node.exe" set "PATH=%V%\node;%PATH%"

echo ---- 1. main's tools >> "%RES%"
if not exist "%C%\.git" (
  git -c core.autocrlf=false clone -q --filter=blob:none --no-checkout https://github.com/rcbailey12/voidsworn.git "%C%" >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=git clone failed" & goto fail)
  git -C "%C%" sparse-checkout set tools >> "%RES%" 2>&1
)
git -C "%C%" fetch -q origin main >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=fetch of main failed" & goto fail)
git -C "%C%" checkout -q -f --detach FETCH_HEAD >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=checkout of main failed" & goto fail)
for /f %%H in ('git -C "%C%" rev-parse HEAD') do echo main %%H >> "%RES%"
findstr /c:"NullString" "%C%\tools\pc\lane_tools_refresh.ps1" > nul || (set "FAILMSG=main does not have the PR 1284 pointer fix yet; nothing installed" & goto fail)
for %%F in (scratch_done.ps1 helper_clone.ps1 janitor.ps1) do if not exist "%C%\tools\pc\%%F" (set "FAILMSG=main has no tools\pc\%%F yet; nothing installed" & goto fail)
findstr /c:"--after-job" "%C%\tools\pc\job_wrap.bat" > nul || (set "FAILMSG=main's job_wrap.bat has no after-job cleanup yet; nothing installed" & goto fail)

echo ---- 2. before: versions, and no job starting >> "%RES%"
set "PREV="
if exist "%TL%\current.txt" set /p PREV=<"%TL%\current.txt"
echo current before: !PREV! >> "%RES%"
powershell -NoProfile -Command "$tl=$env:TL; if (-not (Test-Path -LiteralPath $tl)) { 'versions: 0'; exit 0 }; $v=@(Get-ChildItem -LiteralPath $tl -Directory -Force | Where-Object Name -Match '^[0-9a-f]{12}$'); 'versions: ' + $v.Count; $v | Sort-Object CreationTimeUtc | ForEach-Object { '  ' + $_.Name + '  ' + $_.CreationTimeUtc.ToString('o') }; if ($v.Count -ge 4 -and @($v | Where-Object { $_.CreationTimeUtc -lt [DateTime]::UtcNow.AddHours(-24) }).Count) { exit 3 }; exit 0" > "%O%\versions_before.txt" 2>&1
set "VX=!ERRORLEVEL!"
type "%O%\versions_before.txt" >> "%RES%"
if "!VX!"=="3" (set "FAILMSG=four or more tools_live versions exist and one is over a day old, so the install could rotate it out; nothing installed (the next job start installs it under the rotation rule)" & goto fail)
if not "!VX!"=="0" (set "FAILMSG=could not list tools_live versions" & goto fail)
powershell -NoProfile -Command "$p=Join-Path $env:V 'lane_tools_refresh.lock'; $end=(Get-Date).AddMinutes(5); while ($true) { try { $h=[IO.File]::Open($p,'OpenOrCreate','ReadWrite','None'); $h.Dispose(); 'refresh lock free'; exit 0 } catch [IO.IOException] { if ((Get-Date) -ge $end) { 'refresh lock still held after 5 minutes (a job is starting)'; exit 1 }; Start-Sleep -Seconds 5 } }" >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=a job is starting (refresh lock held 5 minutes); nothing installed" & goto fail)

echo ---- 3. install tools_live >> "%RES%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%C%\tools\pc\lane_tools_refresh.ps1" -Build tools_live > "%O%\install.txt" 2>&1
set "IX=!ERRORLEVEL!"
type "%O%\install.txt" >> "%RES%"
if not "!IX!"=="0" (set "FAILMSG=install exit !IX!" & goto fail)
findstr /c:"rotated out" "%O%\install.txt" > nul && (set "FAILMSG=the refresh rotated out an old version, which should not happen under four versions; see install.txt" & goto fail)
set "CUR="
if exist "%TL%\current.txt" set /p CUR=<"%TL%\current.txt"
if not defined CUR (set "FAILMSG=no current.txt after the install" & goto fail)
echo current after: !CUR! >> "%RES%"
if "!CUR!"=="!PREV!" (set "FAILMSG=current.txt still names !PREV!; the switch did not happen" & goto fail)
findstr /c:"NullString" "%TL%\!CUR!\pc\lane_tools_refresh.ps1" > nul || (set "FAILMSG=the new version's refresh lacks the pointer fix" & goto fail)
echo hashes.txt of the new version: >> "%RES%"
type "%TL%\!CUR!\hashes.txt" >> "%RES%"
if defined PREV if exist "%TL%\!PREV!\hashes.txt" echo previous version kept: tools_live\!PREV! >> "%RES%"
for %%F in (tmo.bat run_timeout.ps1 gpu_slots.js job_wrap.bat runner_common.ps1 janitor.ps1 scratch_done.ps1 helper_clone.ps1 helper_clone.bat) do if not exist "%TL%\!CUR!\pc\%%F" (set "FAILMSG=tools_live\!CUR!\pc\%%F missing" & goto fail)
findstr /c:"--after-job" "%TL%\!CUR!\pc\job_wrap.bat" > nul || (set "FAILMSG=installed job_wrap.bat has no after-job cleanup" & goto fail)
powershell -NoProfile -ExecutionPolicy Bypass -File "%TL%\!CUR!\pc\runner_common.ps1" hashcheck "%O%" "%TL%\!CUR!\pc" "%TL%\!CUR!\hashes.txt" strict >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=the installed version fails the strict hash check" & goto fail)

echo ---- 4. an old tmo.bat copy hands off to tools_live >> "%RES%"
set "OLDC=%O%\oldcopy\tools\pc"
mkdir "%OLDC%"
if defined PREV if exist "%TL%\!PREV!\pc\tmo.bat" (copy /y "%TL%\!PREV!\pc\tmo.bat" "%OLDC%\tmo.bat" > nul) else (copy /y "%TL%\!CUR!\pc\tmo.bat" "%OLDC%\tmo.bat" > nul)
if not exist "%OLDC%\tmo.bat" copy /y "%TL%\!CUR!\pc\tmo.bat" "%OLDC%\tmo.bat" > nul
set "PC_GPU_ISSUE=opus1180_tools_install"
set "TMO_SAY_WATCHDOG=1"
call "%OLDC%\tmo.bat" 60 "%ComSpec%" /c echo install step ran > "%O%\handoff.txt" 2>&1
set "HX=!ERRORLEVEL!"
set "TMO_SAY_WATCHDOG="
set "PC_GPU_ISSUE="
type "%O%\handoff.txt" >> "%RES%"
if not "!HX!"=="0" (set "FAILMSG=hand-off step exit !HX!" & goto fail)
find "tmo: watchdog %TL%\!CUR!\pc\run_timeout.ps1" "%O%\handoff.txt" > nul || (set "FAILMSG=the old copy did not hand off to the new tools_live watchdog" & goto fail)
find "install step ran" "%O%\handoff.txt" > nul || (set "FAILMSG=the hand-off step did not run" & goto fail)

echo ---- 5. an ordinary job_wrap init resolves the new version >> "%RES%"
set "JWO=%O%\jobwrap"
call :jobwrap_probe
if not "!JWX!"=="0" (set "FAILMSG=job_wrap init exit !JWX!; see %JWO%\status.txt" & goto fail)
type "%JWO%\status.txt" >> "%RES%"
find "tools: %TL%\!CUR!\pc" "%JWO%\status.txt" > nul || (set "FAILMSG=job_wrap did not resolve tools_live\!CUR!" & goto fail)
find "ready: GPU label" "%JWO%\status.txt" > nul || (set "FAILMSG=job_wrap init did not reach ready" & goto fail)

echo ---- 6. janitor dry run (removes nothing) >> "%RES%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%TL%\!CUR!\pc\janitor.ps1" --dry-run > "%O%\janitor_dry.txt" 2>&1
set "DX=!ERRORLEVEL!"
echo janitor dry run exit !DX!, full list in janitor_dry.txt >> "%RES%"
findstr /c:"would remove" /c:"free space" /c:"Board keep list" /c:"janitor stopped" "%O%\janitor_dry.txt" >> "%RES%"
if not "!DX!"=="0" (set "FAILMSG=janitor dry run exit !DX!" & goto fail)

echo ---- 7. PC doctor, read only >> "%RES%"
set "PC_DOCTOR_NO_PAUSE=1"
call "%TL%\!CUR!\pc\PC_DOCTOR.bat" > "%O%\pc_doctor.txt" 2>&1
type "%O%\pc_doctor.txt" >> "%RES%"
echo PASSED >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0

:jobwrap_probe
rem The real job_wrap.bat of the new version, as a job bat calls it: its own setlocal, init (with the usual tools_live
rem refresh), a no-op note, end. JW_NO_JANITOR=1: this probe does not start the after-job cleanup (step 6 runs the dry run).
setlocal
set "JW_NO_JANITOR=1"
set "JW=%TL%\!CUR!\pc\job_wrap.bat"
call "%JW%" init "%JWO%" "opus1180_install2" "node"
set "RC=%ERRORLEVEL%"
if "%RC%"=="0" call "%JW%" note "install 2 probe"
if "%RC%"=="0" call "%JW%" end
endlocal & set "JWX=%RC%"
exit /b 0

:fail
echo FAILED: !FAILMSG! >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 1
