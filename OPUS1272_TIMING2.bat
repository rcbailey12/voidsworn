@echo off
title Opus 1272 run 2: first battle load per stop, with and without its mood - GPU solo timing
rem Issue 1272 (Opus helper): does a stop mood (new sky bake) or a planet remix add a visible stall on first load?
rem godot/world/stop_sky_timing.gd on opus/issue-1272 (pinned below) loads a plain stop first (primes the sector bake, as the
rem sector map does), frees it, then times the target stop: ms to the end of warm-up and the worst frame in the next 180.
rem Four kinds (plain, boss, salvage, rival), each in its own process and its own empty profile, so the disk bake cache
rem starts empty every time. Frame times: GPU solo (R293). 1280x720, quality max.
rem Its own sparse clone in opus1272\repo; hulls copied in from build\godot (copy only). Every Godot start goes through
rem tools_live\<current.txt>\pc\tmo.bat (fails closed if missing). Never deletes anything.
rem Run 2: the mood no longer rebakes the sky (eb34c75d). Each kind runs twice: with its mood, and --no-stop (same scene,
rem fleet and map, no mood), so the mood cost is the difference. 8 runs.
rem Logs to out_<A>\result.txt (STOP_TIMING lines) and ends with "all done".
setlocal EnableDelayedExpansion
set REF=eb34c75d7252b21ff106926be9c95fc9bb09de82
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1272
set C=%W%\repo
if not exist "%W%" mkdir "%W%"
set A=1
:findattempt
if exist "%W%\out_%A%" (set /a A+=1 & goto findattempt)
set O=%W%\out_%A%
mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% attempt %A% > "%RES%"
findstr /b /c:"GPU cleared" "%V%\gpu_go.txt" >nul 2>&1 || (echo gpu_go.txt is not GPU cleared: stopped >> "%RES%" & echo all done >> "%RES%" & exit /b 0)
set "TLV="
if exist "%V%\tools_live\current.txt" set /p TLV=<"%V%\tools_live\current.txt"
if not defined TLV (set "FAILMSG=tools_live\current.txt is missing or empty" & goto fail)
set "TM=%V%\tools_live\%TLV%\pc\tmo.bat"
if not exist "%TM%" (set "FAILMSG=no watchdog at %TM%" & goto fail)
if not exist "%V%\tools_live\%TLV%\pc\run_timeout.ps1" (set "FAILMSG=no run_timeout.ps1 beside %TM%" & goto fail)
echo watchdog %TM% >> "%RES%"
certutil -hashfile "%TM%" SHA256 >> "%RES%" 2>&1
if not exist "%C%\.git" (
  git clone -q --filter=blob:none --no-checkout https://github.com/rcbailey12/voidsworn.git "%C%" >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=git clone failed" & goto fail)
  git -C "%C%" sparse-checkout set godot tools >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=sparse-checkout failed" & goto fail)
)
git -C "%C%" fetch -q origin opus/issue-1272 >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=git fetch failed" & goto fail)
git -C "%C%" checkout -q --no-overwrite-ignore --detach %REF% >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=checkout %REF% refused; nothing was forced" & goto fail)
for /f %%H in ('git -C "%C%" rev-parse HEAD') do echo commit %%H >> "%RES%"
robocopy "%V%\build\godot\assets\ships" "%C%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NP > "%O%\log_copy_ships.txt" 2>&1
if %ERRORLEVEL% GEQ 8 (set "FAILMSG=copy ships failed" & goto fail)
if exist "%V%\build\godot\gen" robocopy "%V%\build\godot\gen" "%C%\godot\gen" /E /NFL /NDL /NJH /NP > "%O%\log_copy_gen.txt" 2>&1
if %ERRORLEVEL% GEQ 8 (set "FAILMSG=copy gen failed" & goto fail)
git -C "%C%" status --porcelain --untracked-files=no -- "*.gd" > "%O%\tracked_gd_changes.txt" 2>&1
for %%Z in ("%O%\tracked_gd_changes.txt") do if %%~zZ GTR 0 (set "FAILMSG=tracked .gd files changed after the ships copy" & goto fail)
set "REAL_APPDATA=%APPDATA%"
set "REAL_LOCALAPPDATA=%LOCALAPPDATA%"
set "PROF=%W%\profile_%A%"
mkdir "%PROF%"
set "APPDATA=%PROF%"
set "LOCALAPPDATA=%PROF%"
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set PC_GPU_ISSUE=1272
set PC_GPU_MODE=solo
set VS_TIMING_QUALITY=max
call "%TM%" 3600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
set GOOD=0
call :timing plain
call :timing boss
call :timing salvage
call :timing rival
call :timing plain --no-stop
call :timing boss --no-stop
call :timing salvage --no-stop
call :timing rival --no-stop
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%REAL_LOCALAPPDATA%"
echo timings collected !GOOD! of 8 >> "%RES%"
if not "!GOOD!"=="8" (set "FAILMSG=only !GOOD! of 8 timings ran" & goto fail)
echo PASSED >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0

:timing
set "APPDATA=%PROF%\t_%1%2"
set "LOCALAPPDATA=%PROF%\t_%1%2"
mkdir "%APPDATA%"
call "%TM%" 1200 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1280x720 --script res://world/stop_sky_timing.gd -- --stop-kind %1 %2 > "%O%\log_%1%2.txt" 2>&1
echo %1 %2 exit !ERRORLEVEL! >> "%RES%"
findstr /c:"STOP_TIMING" "%O%\log_%1%2.txt" >> "%RES%" && set /a GOOD+=1
exit /b 0

:fail
echo FAILED: %FAILMSG% >> "%RES%"
if defined REAL_APPDATA (set "APPDATA=%REAL_APPDATA%" & set "LOCALAPPDATA=%REAL_LOCALAPPDATA%")
echo all done %DATE% %TIME% >> "%RES%"
exit /b 1
