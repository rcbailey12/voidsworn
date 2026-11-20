@echo off
title Opus 1180: install main's tools as a new tools_live version (no idle wait, deletes nothing)
rem Issue 1180 rollout (Board, Nov 20), after PRs 1266, 1275, 1277, 1278 and 1280 merged (main 4f9dbabd or later).
rem Installs origin/main's tools as a new Downloads\voidsworn_test\tools_live\<version>\ next to the current one through
rem main's own lane_tools_refresh.ps1 -Build tools_live (stage, verify every file, write hashes.txt, then flip current.txt in
rem one rename). Running jobs keep the version they already resolved; only jobs that start afterwards use the new one.
rem It does not wait for an idle GPU: 1180 changed run_timeout.ps1 only in how it removes its own Godot profile, and
rem gpu_slots.js is unchanged, so old and new watchdogs share one claim protocol.
rem It deletes nothing: the refresh rotates out an old version only when more than four exist, so this stops before the
rem install when four or more versions are already there (the janitor's rotation rule then runs at a later job start).
rem It refuses while a job is starting: a starting job holds lane_tools_refresh.lock while it refreshes; this waits up to
rem 5 minutes for that lock to be free, then stops.
rem Checks after the install: the 1180 files are present, the strict hash check passes, and a step through an old copy
rem of tmo.bat hands off to the new tools_live watchdog. Last, PC_DOCTOR (read only).
rem Log: opus1180\tools_install_<A>\result.txt, PASSED or FAILED, then all done.
setlocal EnableDelayedExpansion
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1180
set C=%W%\main
set TL=%V%\tools_live
if not exist "%W%" mkdir "%W%"
set A=1
:findattempt
if exist "%W%\tools_install_%A%" (set /a A+=1 & goto findattempt)
set O=%W%\tools_install_%A%
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
for %%F in (scratch_done.ps1 helper_clone.ps1 janitor.ps1) do if not exist "%C%\tools\pc\%%F" (set "FAILMSG=main has no tools\pc\%%F yet; nothing installed" & goto fail)
findstr /c:"--after-job" "%C%\tools\pc\job_wrap.bat" > nul || (set "FAILMSG=main's job_wrap.bat has no after-job cleanup yet; nothing installed" & goto fail)

echo ---- 2. before: versions, and no job starting >> "%RES%"
set "PREV="
if exist "%TL%\current.txt" set /p PREV=<"%TL%\current.txt"
echo current before: !PREV! >> "%RES%"
powershell -NoProfile -Command "$tl=$env:TL; if (-not (Test-Path -LiteralPath $tl)) { 'versions: 0'; exit 0 }; $v=@(Get-ChildItem -LiteralPath $tl -Directory -Force | Where-Object Name -Match '^[0-9a-f]{12}$'); 'versions: ' + $v.Count; $v | Sort-Object CreationTimeUtc | ForEach-Object { '  ' + $_.Name + '  ' + $_.CreationTimeUtc.ToString('o') }; if ($v.Count -ge 4) { exit 3 }; exit 0" > "%O%\versions_before.txt" 2>&1
set "VX=!ERRORLEVEL!"
type "%O%\versions_before.txt" >> "%RES%"
if "!VX!"=="3" (set "FAILMSG=four or more tools_live versions exist, so the install could rotate one out; nothing installed (the next job start installs it under the rotation rule)" & goto fail)
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

echo ---- 5. PC doctor, read only >> "%RES%"
set "PC_DOCTOR_NO_PAUSE=1"
call "%TL%\!CUR!\pc\PC_DOCTOR.bat" > "%O%\pc_doctor.txt" 2>&1
type "%O%\pc_doctor.txt" >> "%RES%"
echo PASSED >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0

:fail
echo FAILED: !FAILMSG! >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 1
