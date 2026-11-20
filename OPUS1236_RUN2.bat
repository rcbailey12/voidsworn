@echo off
title Opus 1236: wrecks in their blocking hex - GPU picture job
rem Issue 1236 (PR on opus/issue-1236): a dead cruiser and capital's wreck should sit in the hex it blocks.
rem 1. the headless check on the PC's installed hulls (wreck_hex_check.gd, quality low and max)
rem 2. the same check windowed on the GPU, which saves two top-down c170 pictures 8 s after the kills, 720 px tall:
rem    WH1236.png (the game's look) and WH1236_grid.png (grid on, Z), each with its code name and commit
rem Its own sparse clone in opus1236\repo (godot and tools only; made on the first run). Every Godot start runs in its own
rem throwaway profile (opus1236\profile_<N>); Ryan's real battle_opts.json and board_look.cfg are hashed before and after,
rem and a difference is FAILED. Writes only under opus1236\ (out_<A>, A the first unused attempt number). Never deletes.
rem Logs to out_<A>\result.txt and ends with "all done".
setlocal EnableDelayedExpansion
set REF=da6546506da2695e33bab7cafc99d9661640ce3b
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1236
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
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
if not exist "%C%\.git" (
  git clone -q --filter=blob:none --no-checkout --depth 1 https://github.com/rcbailey12/voidsworn.git "%C%" >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=git clone failed" & goto fail)
  git -C "%C%" sparse-checkout set godot tools >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=sparse-checkout failed" & goto fail)
  echo made the sparse clone >> "%RES%"
)
git -C "%C%" fetch -q --depth 1 origin %REF% >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=git fetch of %REF% failed" & goto fail)
git -C "%C%" status --porcelain --untracked-files=no -- . ":(exclude)godot/assets/ships" ":(glob,exclude)godot/**/*.import" > "%O%\clone_changes_unexpected.txt" 2>> "%RES%"
for %%Z in ("%O%\clone_changes_unexpected.txt") do if %%~zZ GTR 0 (set "FAILMSG=the clone has local changes outside godot\assets\ships and the .import files, listed in out; nothing was reset" & goto fail)
git -C "%C%" diff --binary HEAD > "%O%\clone_changes_before_checkout.patch" 2>> "%RES%"
git -C "%C%" checkout -q HEAD -- godot/assets/ships >> "%RES%" 2>&1
git -C "%C%" checkout -q HEAD -- ":(glob)godot/**/*.import" >> "%RES%" 2>&1
git -C "%C%" checkout -q --no-overwrite-ignore --detach FETCH_HEAD >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=checkout of %REF% refused; nothing was forced" & goto fail)
set COMMIT=
for /f %%H in ('git -C "%C%" rev-parse HEAD') do set COMMIT=%%H
echo commit=%COMMIT% >> "%RES%"
if not "%COMMIT%"=="%REF%" (set "FAILMSG=checked out %COMMIT%, expected %REF%" & goto fail)
echo {"commit": "%COMMIT%"} > "%C%\godot\build_info.json"
rem the installed ships and generated hulls, copied (robocopy /E only adds and updates; exit 0 to 7 is success, 8+ failed)
robocopy "%V%\build\godot\assets\ships" "%C%\godot\assets\ships" /E /NFL /NDL /NJH /NP > "%O%\log_copy_ships.txt" 2>&1
set E=%ERRORLEVEL%
echo copy ships robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (set "FAILMSG=copy ships failed" & goto fail)
if exist "%V%\build\godot\gen" robocopy "%V%\build\godot\gen" "%C%\godot\gen" /E /NFL /NDL /NJH /NP > "%O%\log_copy_gen.txt" 2>&1
set E=%ERRORLEVEL%
echo copy gen robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (set "FAILMSG=copy gen failed" & goto fail)
rem the throwaway profiles: Ryan's real options are hashed first, then every Godot start below uses its own profile
set "REALU=%APPDATA%\Godot\app_userdata\Voidsworn"
set N=1
:findprof
if exist "%W%\profile_%N%" (set /a N+=1 & goto findprof)
set "PROF=%W%\profile_%N%"
mkdir "%PROF%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%O%\real_profile_before.txt" 2>&1
set "REAL_APPDATA=%APPDATA%"
set "REAL_LOCALAPPDATA=%LOCALAPPDATA%"
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set TM=%C%\tools\pc\tmo.bat
set PC_GPU_WAIT_SECONDS=3600
set PC_GPU_ISSUE=1236
"%GD%" --version >> "%RES%" 2>&1
cd /d "%C%"
set "APPDATA=%PROF%\import"
set "LOCALAPPDATA=%PROF%\import"
mkdir "%APPDATA%"
call "%TM%" 3600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
set E=%ERRORLEVEL%
echo import exit %E% >> "%RES%"
if not "%E%"=="0" (set "FAILMSG=import failed" & goto restore_fail)
set "APPDATA=%PROF%\headless"
set "LOCALAPPDATA=%PROF%\headless"
mkdir "%APPDATA%"
call "%TM%" 900 "%GD%" --headless --path "%C%\godot" --script res://scenes/battle/test/wreck_hex_check.gd > "%O%\log_check_headless.txt" 2>&1
set E=%ERRORLEVEL%
echo headless check exit %E% >> "%RES%"
findstr /c:"WRECK_HEX" /c:"FAIL" /c:"SCRIPT ERROR" "%O%\log_check_headless.txt" >> "%RES%"
if not "%E%"=="0" (set "FAILMSG=headless wreck check failed" & goto restore_fail)
set "APPDATA=%PROF%\shot"
set "LOCALAPPDATA=%PROF%\shot"
mkdir "%APPDATA%"
set "WH_REV=%COMMIT:~0,8%"
call "%TM%" 900 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script res://scenes/battle/test/wreck_hex_check.gd -- shot "%O%\WH1236.png" > "%O%\log_check_shot.txt" 2>&1
set E=%ERRORLEVEL%
echo windowed check and pictures exit %E% >> "%RES%"
findstr /c:"WRECK_HEX" /c:"FAIL" /c:"SCRIPT ERROR" "%O%\log_check_shot.txt" >> "%RES%"
if not "%E%"=="0" (set "FAILMSG=windowed wreck check failed" & goto restore_fail)
if not exist "%O%\WH1236.png" (set "FAILMSG=no picture WH1236.png" & goto restore_fail)
if not exist "%O%\WH1236_grid.png" (set "FAILMSG=no picture WH1236_grid.png" & goto restore_fail)
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%REAL_LOCALAPPDATA%"
call :realcheck
if errorlevel 1 (set "FAILMSG=Ryan's real options changed during the run; see real_profile_*.txt" & goto fail)
echo real options unchanged >> "%RES%"
echo PASSED >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0

:realcheck
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%REAL_LOCALAPPDATA%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%O%\real_profile_after.txt" 2>&1
fc /b "%O%\real_profile_before.txt" "%O%\real_profile_after.txt" > nul
exit /b %ERRORLEVEL%

:restore_fail
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%REAL_LOCALAPPDATA%"
:fail
echo FAILED: %FAILMSG% >> "%RES%"
if defined REAL_APPDATA (call :realcheck & if errorlevel 1 (echo FAILED: Ryan's real options changed during the run >> "%RES%") else (echo real options unchanged >> "%RES%"))
echo all done %DATE% %TIME% >> "%RES%"
exit /b 1
