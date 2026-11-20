@echo off
title Opus 1194: one tools copy, preflight, honest exit codes - PC proof (no GPU)
rem Issue 1194 proof on the PC. CPU only: it never claims the GPU and never touches the live queue, the lanes or tools_live.
rem 1. Its own sparse clone of opus/issue-1194 in opus1194\repo (tools and contrib\opus\tools only; made on the first run).
rem 2. The Windows tests: pc_jobs_1194_tests.js (real cmd runs of job_wrap with fake tools: a failed step stops the job, an
rem    optional one does not, a missing tool exits 2 before any step, a changed watchdog stops it, tmo.bat hands off to
rem    tools_live, the doctor reads claims and changes nothing) and lane_tools_refresh_selftest.js.
rem 3. lane_tools_refresh.ps1 -Build tools_live, twice, into a THROWAWAY profile (USERPROFILE=opus1194\profile_<N>), so the
rem    real voidsworn_test is never written: the second run must say "already uses" and the version must match its hashes.
rem 4. PC_DOCTOR (read only) against the real voidsworn_test: today's claims, stuck processes and failed jobs.
rem Writes only under opus1194\ (out_<A>, A the first unused attempt number) and the doctor's own pc_doctor.txt report.
rem Never deletes anything. Logs to out_<A>\result.txt and ends with PASSED or FAILED, then "all done".
setlocal EnableDelayedExpansion
set BRANCH=opus/issue-1194
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1194
set C=%W%\repo
if not exist "%W%" mkdir "%W%"
set A=1
:findattempt
if exist "%W%\out_%A%" (set /a A+=1 & goto findattempt)
set O=%W%\out_%A%
mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% attempt %A% > "%RES%"
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
set "NODE=node"
if exist "%V%\node\node.exe" set "NODE=%V%\node\node.exe"
if not exist "%C%\.git" (
  git -c core.autocrlf=false clone -q --filter=blob:none --no-checkout https://github.com/rcbailey12/voidsworn.git "%C%" >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=git clone failed" & goto fail)
  git -C "%C%" sparse-checkout set tools contrib/opus/tools >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=sparse-checkout failed" & goto fail)
)
git -C "%C%" fetch -q origin %BRANCH% >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=fetch of %BRANCH% failed" & goto fail)
git -C "%C%" checkout -q -f --detach FETCH_HEAD >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=checkout failed" & goto fail)
for /f %%H in ('git -C "%C%" rev-parse HEAD') do echo commit %%H >> "%RES%"

echo ---- pc_jobs_1194_tests >> "%RES%"
"%NODE%" "%C%\contrib\opus\tools\pc_jobs_1194_tests.js" > "%O%\pc_jobs_1194_tests.txt" 2>&1
set "TX=!ERRORLEVEL!"
type "%O%\pc_jobs_1194_tests.txt" >> "%RES%"
if not "!TX!"=="0" (set "FAILMSG=pc_jobs_1194_tests exit !TX!" & goto fail)
findstr /c:"SKIP Windows" "%O%\pc_jobs_1194_tests.txt" > nul && (set "FAILMSG=the Windows runs were skipped" & goto fail)
echo ---- lane_tools_refresh_selftest >> "%RES%"
"%NODE%" "%C%\tools\pc\lane_tools_refresh_selftest.js" >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=lane_tools_refresh_selftest failed" & goto fail)

echo ---- tools_live refresh in a throwaway profile >> "%RES%"
set N=1
:findprof
if exist "%W%\profile_%N%" (set /a N+=1 & goto findprof)
set "PROF=%W%\profile_%N%"
mkdir "%PROF%\Downloads\voidsworn_test"
set "REALPROFILE=%USERPROFILE%"
set "USERPROFILE=%PROF%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%C%\tools\pc\lane_tools_refresh.ps1" -Build tools_live > "%O%\refresh1.txt" 2>&1
set "RX1=!ERRORLEVEL!"
powershell -NoProfile -ExecutionPolicy Bypass -File "%C%\tools\pc\lane_tools_refresh.ps1" -Build tools_live > "%O%\refresh2.txt" 2>&1
set "RX2=!ERRORLEVEL!"
set "USERPROFILE=%REALPROFILE%"
type "%O%\refresh1.txt" >> "%RES%"
type "%O%\refresh2.txt" >> "%RES%"
if not "!RX1!"=="0" (set "FAILMSG=first tools_live refresh exit !RX1!" & goto fail)
if not "!RX2!"=="0" (set "FAILMSG=second tools_live refresh exit !RX2!" & goto fail)
findstr /c:"tools_live already uses" "%O%\refresh2.txt" > nul || (set "FAILMSG=the second refresh did not reuse the installed version" & goto fail)
set "TL=%PROF%\Downloads\voidsworn_test\tools_live"
set /p TLV=<"%TL%\current.txt"
echo tools_live version !TLV! >> "%RES%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%C%\tools\pc\runner_common.ps1" hashcheck "%O%" "%TL%\!TLV!\pc" "%TL%\!TLV!\hashes.txt" strict >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=the installed tools_live version does not match its hashes" & goto fail)
if not exist "%TL%\!TLV!\pc\job_wrap.bat" (set "FAILMSG=tools_live has no job_wrap.bat (main has not got 1194 yet: expected before merge)" & goto softfail)

:doctor
echo ---- PC doctor, read only, real voidsworn_test >> "%RES%"
set "PC_DOCTOR_NO_PAUSE=1"
call "%C%\tools\pc\PC_DOCTOR.bat" > "%O%\pc_doctor.txt" 2>&1
type "%O%\pc_doctor.txt" >> "%RES%"
if defined SOFT (echo PASSED, except: !SOFT! >> "%RES%") else (echo PASSED >> "%RES%")
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0

:softfail
rem Before 1194 merges, main's tools have no job_wrap.bat; the refresh itself is still proven. Go on to the doctor.
set "SOFT=!FAILMSG!"
echo NOTE: !FAILMSG! >> "%RES%"
goto doctor

:fail
echo FAILED: !FAILMSG! >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 1
