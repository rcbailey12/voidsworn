@echo off
title Opus 1194: install tools_live from main (waits for an idle GPU and queue)
rem Issue 1194 rollout (Board, Nov 20), after PR 1254 merged. Installs the one canonical tools copy:
rem   Downloads\voidsworn_test\tools_live\<version>\ plus current.txt, from origin/main, through main's own
rem   lane_tools_refresh.ps1 -Build tools_live (verify, hash, then an atomic switch of current.txt).
rem It waits (up to 3 hours, checking each minute) until no GPU claim is held (every gpu_slot_N and gpu_solo empty or
rem absent) and no job runs in queue\running or queue_b\running. It never stops, moves or edits a running job, the
rem watchers or any lane checkout, and deletes nothing (a first install has no old versions to rotate).
rem It stops without installing if main does not have issue 1194 yet (no tools\pc\job_wrap.bat).
rem Then it checks the install: strict hash check, and a step through an old copy of tmo.bat must hand off to the
rem tools_live watchdog. Last, PC_DOCTOR (read only). Log: opus1194\rollout_<A>\result.txt, PASSED or FAILED, then all done.
setlocal EnableDelayedExpansion
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1194
set C=%W%\main
if not exist "%W%" mkdir "%W%"
set A=1
:findattempt
if exist "%W%\rollout_%A%" (set /a A+=1 & goto findattempt)
set O=%W%\rollout_%A%
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
if not exist "%C%\tools\pc\job_wrap.bat" (set "FAILMSG=main does not have issue 1194 yet (no job_wrap.bat); nothing installed" & goto fail)

echo ---- 2. wait for an idle GPU and queue >> "%RES%"
set /a WAITED=0
:waitidle
set "BUSY="
for %%Q in (queue queue_b) do if exist "%V%\%%Q\running\*.bat" set "BUSY=a job runs in %%Q\running"
if not defined BUSY (
  powershell -NoProfile -Command "$v=$env:V; $held=@(Get-ChildItem -LiteralPath $v -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^gpu_slot_[1-9][0-9]*$' -or $_.Name -eq 'gpu_solo' } | Where-Object { ([IO.File]::ReadAllText($_.FullName)).Trim() }); if ($held.Count) { Write-Output ('held: ' + (($held | ForEach-Object Name) -join ', ')); exit 1 }; exit 0" > "%O%\gpu_check.txt" 2>&1
  if errorlevel 1 set "BUSY=a GPU claim is held"
)
if not defined BUSY goto idle
if !WAITED! GEQ 180 (set "FAILMSG=still busy after 3 hours: !BUSY!; nothing installed" & goto fail)
if !WAITED!==0 echo waiting: !BUSY! %TIME% >> "%RES%"
set /a WAITED+=1
timeout /t 60 /nobreak > nul
goto waitidle
:idle
echo idle after !WAITED! min %TIME% >> "%RES%"

echo ---- 3. install tools_live >> "%RES%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%C%\tools\pc\lane_tools_refresh.ps1" -Build tools_live > "%O%\install.txt" 2>&1
set "IX=!ERRORLEVEL!"
type "%O%\install.txt" >> "%RES%"
if not "!IX!"=="0" (set "FAILMSG=install exit !IX!" & goto fail)
set "TL=%V%\tools_live"
set "CUR="
if exist "%TL%\current.txt" set /p CUR=<"%TL%\current.txt"
if not defined CUR (set "FAILMSG=no current.txt after the install" & goto fail)
echo current !CUR! >> "%RES%"
for %%F in (tmo.bat run_timeout.ps1 gpu_slots.js job_wrap.bat runner_common.ps1) do if not exist "%TL%\!CUR!\pc\%%F" (set "FAILMSG=tools_live\!CUR!\pc\%%F missing" & goto fail)
powershell -NoProfile -ExecutionPolicy Bypass -File "%TL%\!CUR!\pc\runner_common.ps1" hashcheck "%O%" "%TL%\!CUR!\pc" "%TL%\!CUR!\hashes.txt" strict >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=the installed version fails the strict hash check" & goto fail)

echo ---- 4. an old tmo.bat copy hands off to tools_live >> "%RES%"
set "OLDC=%O%\oldcopy\tools\pc"
mkdir "%OLDC%"
copy /y "%TL%\!CUR!\pc\tmo.bat" "%OLDC%\tmo.bat" > nul
set "PC_GPU_ISSUE=opus1194_rollout"
set "TMO_SAY_WATCHDOG=1"
call "%OLDC%\tmo.bat" 60 "%ComSpec%" /c echo rollout step ran > "%O%\handoff.txt" 2>&1
set "HX=!ERRORLEVEL!"
set "TMO_SAY_WATCHDOG="
set "PC_GPU_ISSUE="
type "%O%\handoff.txt" >> "%RES%"
if not "!HX!"=="0" (set "FAILMSG=hand-off step exit !HX!" & goto fail)
find "tmo: watchdog %TL%\!CUR!\pc\run_timeout.ps1" "%O%\handoff.txt" > nul || (set "FAILMSG=the old copy did not hand off to tools_live" & goto fail)
find "rollout step ran" "%O%\handoff.txt" > nul || (set "FAILMSG=the hand-off step did not run" & goto fail)

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
