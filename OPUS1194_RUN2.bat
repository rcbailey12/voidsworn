@echo off
title Opus 1194: tools_live rotation and watchdog hand-off proof (no GPU)
rem Issue 1194, proof 2 (Board, Nov 20). CPU only, never the real voidsworn_test except PC_DOCTOR (read only).
rem  1. pc_jobs_1194_tests.js and lane_tools_refresh_selftest.js at the branch head (the Windows runs must not skip).
rem  2. Rotation in a THROWAWAY profile (opus1194\rot_<N>): six fake old versions dated 2 to 7 days back, the 5-day one held
rem     by a running cmd whose command line names it. lane_tools_refresh.ps1 -Build tools_live installs main and rotates.
rem     Expected: current, the three newest old ones and the held one stay; the 6- and 7-day unused ones are gone.
rem     A second refresh must reuse the installed version, which must pass the strict hash check.
rem  3. Watchdog hand-off in a second THROWAWAY profile (opus1194\hand_<N>) whose tools_live holds this branch's watchdog:
rem     a) ship readback: ship_job calls tools_live\<v>\pc\tmo.bat directly;
rem     b) pinned Blender paint step: a pinned clone holds main's older tmo.bat; ship_job copies the tools_live tmo.bat over
rem        it, and 5_paint_bake.bat runs "%REPO%\tools\pc\tmo.bat". Both must log the tools_live watchdog path.
rem     c) a blank current.txt must stop the pinned step with exit 125 and run nothing.
rem  4. PC_DOCTOR.bat, read only, on the real folder.
rem Deletes only inside its own throwaway profiles (through the refresh under test). Logs to opus1194\out2_<A>\result.txt.
setlocal EnableDelayedExpansion
set BRANCH=opus/issue-1194
set "REALPROFILE=%USERPROFILE%"
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1194
set C=%W%\repo
if not exist "%W%" mkdir "%W%"
set A=1
:findattempt
if exist "%W%\out2_%A%" (set /a A+=1 & goto findattempt)
set O=%W%\out2_%A%
mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% attempt %A% > "%RES%"
set "NODE=node"
if exist "%V%\node\node.exe" set "NODE=%V%\node\node.exe"
if exist "%V%\node\node.exe" set "PATH=%V%\node;%PATH%"
if not exist "%C%\.git" (
  git -c core.autocrlf=false clone -q --filter=blob:none --no-checkout https://github.com/rcbailey12/voidsworn.git "%C%" >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=git clone failed" & goto fail)
  git -C "%C%" sparse-checkout set tools contrib/opus/tools >> "%RES%" 2>&1
)
git -C "%C%" fetch -q origin %BRANCH% >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=fetch of %BRANCH% failed" & goto fail)
git -C "%C%" checkout -q -f --detach FETCH_HEAD >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=checkout failed" & goto fail)
for /f %%H in ('git -C "%C%" rev-parse HEAD') do echo commit %%H >> "%RES%"

echo ---- 1. pc_jobs_1194_tests >> "%RES%"
"%NODE%" "%C%\contrib\opus\tools\pc_jobs_1194_tests.js" > "%O%\pc_jobs_1194_tests.txt" 2>&1
set "TX=!ERRORLEVEL!"
type "%O%\pc_jobs_1194_tests.txt" >> "%RES%"
if not "!TX!"=="0" (set "FAILMSG=pc_jobs_1194_tests exit !TX!" & goto fail)
find "SKIP Windows" "%O%\pc_jobs_1194_tests.txt" > nul && (set "FAILMSG=the Windows runs were skipped" & goto fail)
echo ---- 1. lane_tools_refresh_selftest >> "%RES%"
"%NODE%" "%C%\tools\pc\lane_tools_refresh_selftest.js" >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=lane_tools_refresh_selftest failed" & goto fail)

echo ---- 2. rotation in a throwaway profile >> "%RES%"
set N=1
:findprof
if exist "%W%\rot_%N%" (set /a N+=1 & goto findprof)
set "PROF=%W%\rot_%N%"
set "TL=%PROF%\Downloads\voidsworn_test\tools_live"
mkdir "%TL%"
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $tl=$env:TL; $d=1; foreach ($n in 'f10000000001','f20000000002','f30000000003','f40000000004','f50000000005','f60000000006') { $d++; $p=Join-Path $tl $n; New-Item -ItemType Directory -Path (Join-Path $p 'pc') | Out-Null; Set-Content -LiteralPath (Join-Path $p 'pc\old.txt') -Value $n; (Get-Item -LiteralPath $p).CreationTimeUtc=[DateTime]::UtcNow.AddDays(-$d) }" >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=could not make the fake versions" & goto fail)
rem The held version: a real process whose command line names its folder.
start "hold1194" /min cmd /c "ping -n 600 127.0.0.1 > nul & rem %TL%\f40000000004"
powershell -NoProfile -Command "Start-Sleep -Seconds 3"
set "REALPROFILE=%USERPROFILE%"
set "USERPROFILE=%PROF%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%C%\tools\pc\lane_tools_refresh.ps1" -Build tools_live > "%O%\rotate.txt" 2>&1
set "RX=!ERRORLEVEL!"
set "USERPROFILE=%REALPROFILE%"
type "%O%\rotate.txt" >> "%RES%"
rem End only the holder this job started: the cmd whose command line names the throwaway profile.
powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='cmd.exe'\" | Where-Object { $_.CommandLine -like ('*' + $env:TL + '\f40000000004*') } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >> "%RES%" 2>&1
if not "!RX!"=="0" (set "FAILMSG=refresh exit !RX!" & goto fail)
dir /b "%TL%" >> "%RES%"
set /p CUR=<"%TL%\current.txt"
if not exist "%TL%\!CUR!\hashes.txt" (set "FAILMSG=current version missing" & goto fail)
for %%K in (f10000000001 f20000000002 f30000000003 f40000000004) do if not exist "%TL%\%%K" (set "FAILMSG=%%K should have stayed" & goto fail)
for %%K in (f50000000005 f60000000006) do if exist "%TL%\%%K" (set "FAILMSG=%%K should have been rotated out" & goto fail)
find "kept tools_live\f40000000004: a running process uses it" "%O%\rotate.txt" > nul || (set "FAILMSG=no log line for the held version" & goto fail)
echo ---- 2. second refresh must reuse the installed version >> "%RES%"
set "USERPROFILE=%PROF%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%C%\tools\pc\lane_tools_refresh.ps1" -Build tools_live > "%O%\refresh2.txt" 2>&1
set "RX2=!ERRORLEVEL!"
set "USERPROFILE=%REALPROFILE%"
type "%O%\refresh2.txt" >> "%RES%"
if not "!RX2!"=="0" (set "FAILMSG=second refresh exit !RX2!" & goto fail)
find "tools_live already uses" "%O%\refresh2.txt" > nul || (set "FAILMSG=the second refresh did not reuse the installed version" & goto fail)
powershell -NoProfile -ExecutionPolicy Bypass -File "%C%\tools\pc\runner_common.ps1" hashcheck "%O%" "%TL%\!CUR!\pc" "%TL%\!CUR!\hashes.txt" strict >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=the installed version fails the strict hash check" & goto fail)

echo ---- 3. watchdog hand-off: ship readback and a pinned Blender paint step >> "%RES%"
set N=1
:findhand
if exist "%W%\hand_%N%" (set /a N+=1 & goto findhand)
set "HP=%W%\hand_%N%"
set "HTL=%HP%\Downloads\voidsworn_test\tools_live"
set "HV=b11940000001"
mkdir "%HTL%\%HV%\pc"
for %%F in (tmo.bat run_timeout.ps1 gpu_slots.js) do copy /y "%C%\tools\pc\%%F" "%HTL%\%HV%\pc\%%F" > nul
echo %HV%> "%HTL%\current.txt"
rem The pinned clone: main's watchdog from before 1194 (eace9e2c), with CRLF line ends like a real checkout.
set "PIN=%HP%\pin"
mkdir "%PIN%\tools\pc"
git -C "%C%" show eace9e2c:tools/pc/tmo.bat > "%O%\pinned_tmo_lf.txt" 2>> "%RES%"
if errorlevel 1 (set "FAILMSG=could not read the pinned tmo.bat" & goto fail)
powershell -NoProfile -Command "$t=[IO.File]::ReadAllText($env:O + '\pinned_tmo_lf.txt') -replace '\r?\n',\"`r`n\"; [IO.File]::WriteAllText($env:PIN + '\tools\pc\tmo.bat',$t)" >> "%RES%" 2>&1
find "tools_live" "%PIN%\tools\pc\tmo.bat" > nul && echo note: the pinned tmo.bat already knows tools_live >> "%RES%"
set "USERPROFILE=%HP%"
set "PC_GPU_ISSUE=opus1194_run2"
set "TMO_SAY_WATCHDOG=1"
rem a) ship readback: ship_job sets TMO to tools_live\<v>\pc\tmo.bat and calls it.
set "TMO=%HTL%\%HV%\pc\tmo.bat"
call "%TMO%" 60 "%ComSpec%" /c echo readback step ran > "%O%\handoff_readback.txt" 2>&1
set "HX1=!ERRORLEVEL!"
rem b) pinned paint step: the same copy ship_job makes after checkout, then the stage's own call.
copy /y "%TMO%" "%PIN%\tools\pc\tmo.bat" > nul
set "REPO=%PIN%"
call "%REPO%\tools\pc\tmo.bat" 60 "%ComSpec%" /c echo paint step ran > "%O%\handoff_paint.txt" 2>&1
set "HX2=!ERRORLEVEL!"
rem c) a blank pointer must stop the pinned step.
type nul > "%HTL%\current.txt"
call "%REPO%\tools\pc\tmo.bat" 60 "%ComSpec%" /c echo SHOULD NOT RUN > "%O%\handoff_blank.txt" 2>&1
set "HX3=!ERRORLEVEL!"
set "USERPROFILE=%REALPROFILE%"
set "PC_GPU_ISSUE="
set "TMO_SAY_WATCHDOG="
echo readback exit !HX1!: >> "%RES%"
type "%O%\handoff_readback.txt" >> "%RES%"
echo pinned paint exit !HX2!: >> "%RES%"
type "%O%\handoff_paint.txt" >> "%RES%"
echo blank pointer exit !HX3!: >> "%RES%"
type "%O%\handoff_blank.txt" >> "%RES%"
if not "!HX1!"=="0" (set "FAILMSG=readback step exit !HX1!" & goto fail)
if not "!HX2!"=="0" (set "FAILMSG=pinned paint step exit !HX2!" & goto fail)
if not "!HX3!"=="125" (set "FAILMSG=blank pointer gave exit !HX3!, not 125" & goto fail)
find "tmo: watchdog %HTL%\%HV%\pc\run_timeout.ps1" "%O%\handoff_readback.txt" > nul || (set "FAILMSG=readback did not use the tools_live watchdog" & goto fail)
find "readback step ran" "%O%\handoff_readback.txt" > nul || (set "FAILMSG=readback step did not run" & goto fail)
find "tmo: watchdog %HTL%\%HV%\pc\run_timeout.ps1" "%O%\handoff_paint.txt" > nul || (set "FAILMSG=the pinned paint step did not hand off to tools_live" & goto fail)
find "paint step ran" "%O%\handoff_paint.txt" > nul || (set "FAILMSG=pinned paint step did not run" & goto fail)
find "SHOULD NOT RUN" "%O%\handoff_blank.txt" > nul && (set "FAILMSG=a blank pointer still ran the step" & goto fail)

echo ---- 4. PC doctor, read only, real voidsworn_test >> "%RES%"
set "PC_DOCTOR_NO_PAUSE=1"
call "%C%\tools\pc\PC_DOCTOR.bat" > "%O%\pc_doctor.txt" 2>&1
type "%O%\pc_doctor.txt" >> "%RES%"
echo PASSED >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0

:fail
set "USERPROFILE=%REALPROFILE%"
echo FAILED: !FAILMSG! >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 1
