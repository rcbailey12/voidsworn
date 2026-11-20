@echo off
title Opus backdrop run 1: before/after pictures for issues 1263, 1264, 1267, 1269 - GPU job
rem Backdrop helper thread (Opus, Nov 20 2026). Capture only, no game change. Pictures for PRs 1299, 1301, 1306, 1307.
rem backdrop_shots.gd must sit beside this bat (both from /mnt/project-files/pc/backdrop/). It is copied into each checkout
rem as godot\backdrop_shots.gd (untracked) and run once per set. 1280x720, quality high, cine look, HUD off.
rem Before: main edea741d. After: each fix branch at its exact head (1307 is main with PR 1246 merged, plus its fix).
rem   storm  (1269)  storm beside a nebula, c170 and c26, brightest of 16 frames (a bolt lit), frames kept
rem   dense  (1263)  PERF1070 RUN3 fixture (seed 4103), c170 at the first storm hex, c320 over the storm, c170 on the nebula
rem   planet (1264)  ringed gas giant, camera r 900 at the board edge away from it, facing it, two tilts, plus home view
rem   rocks  (1264)  belt map, camera low at r 26 and r 100 swept across the nearest rock hex, 10 steps each
rem   edges  (1267)  storm beside a nebula, c170 and c26, cine and Z, nebula and world skies
rem Its own sparse clone in opusbackdrop\repo; hulls copied in from build\godot (copy only). Throwaway profile per run (R334).
rem Every Godot start goes through tools_live\<current.txt>\pc\tmo.bat (fails closed if missing). Never deletes anything.
rem Logs to out_<A>\result.txt and ends with "all done". Pictures in out_<A>\<before|after_NNNN>\*.png.
setlocal EnableDelayedExpansion
set REF_MAIN=edea741dd74f6510767d228556c36ca48aa5a570
set REF_1269=969b1c2c22d643e534c22e22673684185dcc3ee0
set REF_1263=3d13f0f067e8a01455f02276d28e790318bfb508
set REF_1264=e338bd068e754f08644dcecdc0446d514595d14f
set REF_1267=ce6c4d5e3da505111e934bb5b9b5300c3f73d935
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opusbackdrop
set C=%W%\repo
set SHOTS=%~dp0backdrop_shots.gd
if not exist "%W%" mkdir "%W%"
set A=1
:findattempt
if exist "%W%\out_%A%" (set /a A+=1 & goto findattempt)
set O=%W%\out_%A%
mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% attempt %A% > "%RES%"
if not exist "%SHOTS%" (set "FAILMSG=backdrop_shots.gd is not beside this bat" & goto fail)
copy /y "%SHOTS%" "%O%\backdrop_shots.gd" > nul
certutil -hashfile "%O%\backdrop_shots.gd" SHA256 >> "%RES%" 2>&1
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
git -C "%C%" fetch -q origin main opus/issue-1263 opus/issue-1264 opus/issue-1267-edges opus/issue-1269 >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=git fetch failed" & goto fail)
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set PC_GPU_ISSUE=1263
set "REAL_APPDATA=%APPDATA%"
set "REAL_LOCALAPPDATA=%LOCALAPPDATA%"
set GOOD=0
set WANT=0
call :ref before %REF_MAIN% "storm:nebula dense:nebula planet:nebula rocks:frontier edges:nebula edges:world"
if defined FAILMSG goto fail
call :ref after_1269 %REF_1269% "storm:nebula"
if defined FAILMSG goto fail
call :ref after_1263 %REF_1263% "dense:nebula"
if defined FAILMSG goto fail
call :ref after_1264 %REF_1264% "planet:nebula rocks:frontier"
if defined FAILMSG goto fail
call :ref after_1267 %REF_1267% "edges:nebula edges:world"
if defined FAILMSG goto fail
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%REAL_LOCALAPPDATA%"
echo sets finished !GOOD! of !WANT! >> "%RES%"
if not "!GOOD!"=="!WANT!" (set "FAILMSG=only !GOOD! of !WANT! sets finished" & goto fail)
echo PASSED >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0

rem ---- :ref NAME SHA "set:region ..."
:ref
set "NAME=%~1"
set "REF=%~2"
set "D=%O%\%NAME%"
mkdir "%D%"
git -C "%C%" checkout -q --no-overwrite-ignore --detach %REF% >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=checkout %REF% refused; nothing was forced" & exit /b 1)
for /f %%H in ('git -C "%C%" rev-parse HEAD') do (echo %NAME% commit %%H >> "%RES%" & set "BD_COMMIT=%%H")
robocopy "%V%\build\godot\assets\ships" "%C%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NP > "%D%\log_copy_ships.txt" 2>&1
if !ERRORLEVEL! GEQ 8 (set "FAILMSG=copy ships failed" & exit /b 1)
if exist "%V%\build\godot\gen" robocopy "%V%\build\godot\gen" "%C%\godot\gen" /E /NFL /NDL /NJH /NP > "%D%\log_copy_gen.txt" 2>&1
if !ERRORLEVEL! GEQ 8 (set "FAILMSG=copy gen failed" & exit /b 1)
git -C "%C%" status --porcelain --untracked-files=no -- "*.gd" > "%D%\tracked_gd_changes.txt" 2>&1
for %%Z in ("%D%\tracked_gd_changes.txt") do if %%~zZ GTR 0 (set "FAILMSG=tracked .gd files changed after the ships copy (%NAME%)" & exit /b 1)
copy /y "%O%\backdrop_shots.gd" "%C%\godot\backdrop_shots.gd" > nul
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%REAL_LOCALAPPDATA%"
call "%TM%" 3600 "%GD%" --headless --path "%C%\godot" --import > "%D%\log_import.txt" 2>&1
echo %NAME% import exit !ERRORLEVEL! >> "%RES%"
for %%S in (%~3) do call :shot %%S
exit /b 0

rem ---- :shot set:region (one Godot run in its own throwaway profile)
:shot
for /f "tokens=1,2 delims=:" %%P in ("%~1") do (set "BDSET=%%P" & set "REGION=%%Q")
set /a WANT+=1
set "PROF=%W%\profile_%A%_%NAME%_%BDSET%_%REGION%"
mkdir "%PROF%"
set "APPDATA=%PROF%"
set "LOCALAPPDATA=%PROF%"
set "TAG=%NAME%"
if /i "%NAME:~0,6%"=="after_" set "TAG=after"
call "%TM%" 1500 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1280x720 --script res://backdrop_shots.gd -- --out "%D%" --set !BDSET! --region !REGION! --tag !TAG! > "%D%\log_!BDSET!_!REGION!.txt" 2>&1
set "EC=!ERRORLEVEL!"
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%REAL_LOCALAPPDATA%"
echo %NAME% !BDSET! !REGION! exit !EC! >> "%RES%"
findstr /c:"backdrop shots: done" "%D%\log_!BDSET!_!REGION!.txt" >nul 2>&1 && set /a GOOD+=1
findstr /c:"placeholder hull" "%D%\log_!BDSET!_!REGION!.txt" >> "%RES%" 2>nul
exit /b 0

:fail
echo FAILED: %FAILMSG% >> "%RES%"
if defined REAL_APPDATA (set "APPDATA=%REAL_APPDATA%" & set "LOCALAPPDATA=%REAL_LOCALAPPDATA%")
echo all done %DATE% %TIME% >> "%RES%"
exit /b 1
