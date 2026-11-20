@echo off
title Opus 1270 run 1: region light tint preview (boneyard) with real hulls - GPU job
rem Issue 1270 (Opus helper, sky and lighting thread): pictures for Ryan's region light choice. Capture only, no game change.
rem godot/world/sky_sheet_shots.gd on opus/issue-1268 (pinned below) draws the same storm-map battle with the real hulls,
rem and lays a share of the region's sky tint on the key light, fill and ambient (the #362 rim light is not touched).
rem Shots: boneyard at tint 0 (today), 0.10, 0.18, 0.30; nebula region at 0 (the untouched region); each at camera 170 and
rem a camera 26 close-up on a player hull. 1920x1080, quality high.
rem Its own sparse clone in opus1270\repo; hulls copied in from build\godot (copy only). Throwaway profile per run (R334).
rem Every Godot start goes through tools_live\<current.txt>\pc\tmo.bat (fails closed if missing). Never deletes anything.
rem Logs to out_<A>\result.txt and ends with "all done". Pictures in out_<A>\shots\*.png.
setlocal EnableDelayedExpansion
set REF=17463bb157d8c2bea266c512ddb561495370ffc7
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1270
set C=%W%\repo
if not exist "%W%" mkdir "%W%"
set A=1
:findattempt
if exist "%W%\out_%A%" (set /a A+=1 & goto findattempt)
set O=%W%\out_%A%
mkdir "%O%"
mkdir "%O%\shots"
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
git -C "%C%" fetch -q origin opus/issue-1268 >> "%RES%" 2>&1
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
set PC_GPU_ISSUE=1270
call "%TM%" 3600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
set GOOD=0
call :shot boneyard L00 0
call :shot boneyard L10 0.10
call :shot boneyard L18 0.18
call :shot boneyard L30 0.30
call :shot nebula L00 0
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%REAL_LOCALAPPDATA%"
echo shots collected !GOOD! of 5 runs >> "%RES%"
if not "!GOOD!"=="5" (set "FAILMSG=only !GOOD! of 5 runs saved pictures" & goto fail)
echo PASSED >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0

:shot
call "%TM%" 1200 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1280x720 --script res://world/sky_sheet_shots.gd -- --out "%O%\shots" --region %1 --tag %2 --light %3 --ship-close > "%O%\log_%1_%2.txt" 2>&1
echo %1 %2 exit !ERRORLEVEL! >> "%RES%"
if exist "%O%\shots\%1_%2_c26.png" set /a GOOD+=1
findstr /c:"placeholder hull" "%O%\log_%1_%2.txt" >> "%RES%" 2>nul
exit /b 0

:fail
echo FAILED: %FAILMSG% >> "%RES%"
if defined REAL_APPDATA (set "APPDATA=%REAL_APPDATA%" & set "LOCALAPPDATA=%REAL_LOCALAPPDATA%")
echo all done %DATE% %TIME% >> "%RES%"
exit /b 1
