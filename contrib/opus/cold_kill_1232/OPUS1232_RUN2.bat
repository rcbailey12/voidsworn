@echo off
title Opus 1232 run 2: first capital kill, before and after - GPU job
rem Issue 1232 run 2 (replaces OPUS1232_RUN.bat: the fix merged with main (fitted shield pass 1241 included) against that main, 5 s cap, two cores free; Artoo on PR 1240).
rem Issue 1232: a capital's first death froze the game for 3 to 7 s and could lose its pieces (1077 PC rerun, Nov 19).
rem This times A16's first death in fresh processes, on current main before the fix and on the fix merged with that main, three sessions each:
rem   arrival  the battle-like case: warm-up at load with only the shooter, then A16 arrives (as a reinforcement does)
rem            and is killed 6 frames later, before its cut is ready
rem   cold     nothing warmed at all, killed 6 frames after it appears (1077's cold rows)
rem Frames are paced to 60 a second. Also runs the new headless check (cold_kill_check) and death_seam_check on the
rem installed A16 for the fix commit.
rem Its own sparse clone in opus1232\repo (godot, tools and contrib\opus\cold_kill_1232 only; made on the first run).
rem Every Godot start runs in its own throwaway profile (opus1232\profile_<N>\s<K>), so every session starts with an empty
rem shader cache, as a first session does; Ryan's real battle_opts.json and board_look.cfg are hashed before and after,
rem and a difference is FAILED. Start it after any frame-time job holding the GPU; it waits up to an hour per GPU claim.
rem Writes only under opus1232\ (out_<A>, A the first unused attempt number). Never deletes anything.
rem PASSED needs all 12 rows collected AND all three after\arrival kills fractured with pieces; the arrival and kill frame
rem costs are in each CAPTURE1232 line copied into result.txt (a hitch moved to the arrival still shows there).
rem Logs to out_<A>\result.txt and ends with "all done".
setlocal EnableDelayedExpansion
set AFTER=98d470c47bbb09b77e64ba281c9b9650cb5b272d
set BEFORE=d2717a321366f81e639f0ad21336f905e47c30e8
set CAPREF=cf98fc93a6d183f7bed0e8e528c1d052ec47931f
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1232
set C=%W%\repo
if not exist "%W%" mkdir "%W%"
set A=1
:findattempt
if exist "%W%\out_%A%" (set /a A+=1 & goto findattempt)
set O=%W%\out_%A%
mkdir "%O%"
set RES=%O%\result.txt
set BAD=0
set GOOD=0
echo start %DATE% %TIME% attempt %A% > "%RES%"
findstr /b /c:"GPU cleared" "%V%\gpu_go.txt" >nul 2>&1 || (echo gpu_go.txt is not GPU cleared: stopped >> "%RES%" & echo all done >> "%RES%" & exit /b 0)
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
if not exist "%C%\.git" (
  git clone -q --filter=blob:none --no-checkout --depth 1 https://github.com/rcbailey12/voidsworn.git "%C%" >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=git clone failed" & goto fail)
  git -C "%C%" sparse-checkout set godot tools contrib/opus/cold_kill_1232 >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=sparse-checkout failed" & goto fail)
  git -C "%C%" checkout -q main >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=first checkout of the sparse clone failed" & goto fail)
  echo made the sparse clone >> "%RES%"
)
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
set PC_GPU_WAIT_SECONDS=3600
set PC_GPU_ISSUE=1232
"%GD%" --version >> "%RES%" 2>&1
for %%K in (after before) do (
  set "WHICH=%%K"
  call :one_commit
  if errorlevel 1 goto fail
)
set PC_GPU_MODE=
echo timing results collected !GOOD! of 12 (every row is kept as evidence, the before and cold rows are expected to show the problem) >> "%RES%"
rem acceptance (Artoo on PR 1240): every afterrrival row fractured with at least one hull piece, watched past the cap
set ACCEPT=0
for %%N in (1 2 3) do (
  set "J=%O%\after\s%%N\arrival.json"
  findstr /c:"\"outcome\": \"fractured\"" "!J!" >nul 2>&1 && (findstr /c:"\"hull_pieces\": 0," "!J!" >nul 2>&1 || set /a ACCEPT+=1)
)
echo after arrival rows fractured with pieces !ACCEPT! of 3 >> "%RES%"
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
if not "!GOOD!"=="12" (set "FAILMSG=only !GOOD! of 12 timing results were collected" & goto fail)
if not "!ACCEPT!"=="3" (set "FAILMSG=only !ACCEPT! of 3 after arrival kills broke into pieces" & goto fail)
call :realcheck
if errorlevel 1 (set "FAILMSG=Ryan's real options changed during the run; see real_profile_*.txt" & goto fail)
echo real options unchanged >> "%RES%"
echo PASSED >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0

rem ---------------------------------------------------------------- :one_commit (WHICH = after or before)
:one_commit
if "%WHICH%"=="after" (set "REF=%AFTER%") else (set "REF=%BEFORE%")
set "OK=%O%\%WHICH%"
mkdir "%OK%"
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%REAL_LOCALAPPDATA%"
git -C "%C%" fetch -q --depth 1 origin %REF% >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=git fetch of %REF% failed" & exit /b 1)
call :safe_checkout FETCH_HEAD
if errorlevel 1 exit /b 1
set COMMIT=
for /f %%H in ('git -C "%C%" rev-parse HEAD') do set COMMIT=%%H
echo %WHICH% commit=%COMMIT% >> "%RES%"
if not "%COMMIT%"=="%REF%" (set "FAILMSG=checked out %COMMIT%, expected %REF%" & exit /b 1)
echo {"commit": "%COMMIT%"} > "%C%\godot\build_info.json"
rem the installed ships and generated hulls, copied (robocopy /E only adds and updates; exit 0 to 7 is success, 8+ failed)
robocopy "%V%\build\godot\assets\ships" "%C%\godot\assets\ships" /E /NFL /NDL /NJH /NP > "%OK%\log_copy_ships.txt" 2>&1
set E=%ERRORLEVEL%
echo copy ships robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (set "FAILMSG=copy ships failed" & exit /b 1)
if exist "%V%\build\godot\gen" robocopy "%V%\build\godot\gen" "%C%\godot\gen" /E /NFL /NDL /NJH /NP > "%OK%\log_copy_gen.txt" 2>&1
set E=%ERRORLEVEL%
echo copy gen robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (set "FAILMSG=copy gen failed" & exit /b 1)
if not exist "%C%\godot\bench\opus1232" mkdir "%C%\godot\bench\opus1232"
rem the capture comes from CAPREF both times (same game code as AFTER; the before commit does not have it)
git -C "%C%" show %CAPREF%:contrib/opus/cold_kill_1232/capture1232.gd > "%C%\godot\bench\opus1232\capture1232.gd" 2>> "%RES%"
if errorlevel 1 (
  git -C "%C%" fetch -q --depth 1 origin %CAPREF% >> "%RES%" 2>&1
  git -C "%C%" show %CAPREF%:contrib/opus/cold_kill_1232/capture1232.gd > "%C%\godot\bench\opus1232\capture1232.gd" 2>> "%RES%"
  if errorlevel 1 (set "FAILMSG=could not write the capture script" & exit /b 1)
)
set TM=%C%\tools\pc\tmo.bat
cd /d "%C%"
set "APPDATA=%PROF%\import_%WHICH%"
set "LOCALAPPDATA=%PROF%\import_%WHICH%"
mkdir "%APPDATA%"
call "%TM%" 3600 "%GD%" --headless --path "%C%\godot" --import > "%OK%\log_import.txt" 2>&1
set E=%ERRORLEVEL%
echo %WHICH% import exit %E% >> "%RES%"
if not "%E%"=="0" (set "FAILMSG=%WHICH% import failed" & exit /b 1)
if "%WHICH%"=="after" (
  call "%TM%" 1800 "%GD%" --headless --path "%C%\godot" --script res://fx/test/cold_kill_check.gd -- "%C%\godot\assets\ships\C19_51\C19_51.glb" > "%OK%\log_cold_kill_check.txt" 2>&1
  set E=!ERRORLEVEL!
  echo cold kill check exit !E! >> "%RES%"
  if not "!E!"=="0" (set "FAILMSG=cold kill check failed" & exit /b 1)
  call "%TM%" 1800 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\C19_51\C19_51.glb" > "%OK%\log_death_seam.txt" 2>&1
  set E=!ERRORLEVEL!
  echo death seam exit !E! >> "%RES%"
  if not "!E!"=="0" (set "FAILMSG=death seam check failed" & exit /b 1)
)
rem frame times, solo on the GPU (R293): three sessions, each mode in its own process and its own empty profile
set PC_GPU_MODE=solo
for %%N in (1 2 3) do for %%M in (arrival cold) do (
  mkdir "%OK%\s%%N" 2>nul
  set "APPDATA=%PROF%\%WHICH%_s%%N_%%M"
  set "LOCALAPPDATA=%PROF%\%WHICH%_s%%N_%%M"
  mkdir "!APPDATA!"
  call "%TM%" 1800 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1232/capture1232.gd -- %%M "%OK%\s%%N" > "%OK%\s%%N\log_%%M.txt" 2>&1
  set E=!ERRORLEVEL!
  echo %WHICH% s%%N %%M exit !E! >> "%RES%"
  if "!E!"=="0" findstr /c:"\"outcome\"" "%OK%\s%%N\%%M.json" >nul 2>&1 && set /a GOOD+=1
  findstr /c:"CAPTURE1232 %%M" "%OK%\s%%N\log_%%M.txt" >> "%RES%" 2>nul
)
set PC_GPU_MODE=
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%REAL_LOCALAPPDATA%"
exit /b 0

:realcheck
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%REAL_LOCALAPPDATA%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%O%\real_profile_after.txt" 2>&1
fc /b "%O%\real_profile_before.txt" "%O%\real_profile_after.txt" > nul
exit /b %ERRORLEVEL%
:fail
echo FAILED: %FAILMSG% >> "%RES%"
if defined REAL_APPDATA (call :realcheck & if errorlevel 1 (echo FAILED: Ryan's real options changed during the run >> "%RES%") else (echo real options unchanged >> "%RES%"))
echo all done %DATE% %TIME% >> "%RES%"
exit /b 1

rem ---------------------------------------------------------------- :safe_checkout REF (from tools/pc/jobs/shield_looks_1078.bat)
rem Never a forced checkout (file loss, issue 1179). Save the clone's tracked changes first (git status and a binary patch, in
rem the output folder), stop if any is outside godot\assets\ships and the .import files (the only tracked files these jobs
rem write), restore only those from the clone's own commit, then a plain checkout that also refuses to overwrite ignored files.
:safe_checkout
set "SC_REF=%~1"
set "SC_DIR=%O%\checkout_%RANDOM%"
set "SC_LIST="
set "SC_PATCH="
mkdir "%SC_DIR%"
if not exist "%SC_DIR%" (set "FAILMSG=checkout %SC_REF%: could not make %SC_DIR%, nothing was touched" & exit /b 1)
git -C "%C%" status --porcelain --untracked-files=no > "%SC_DIR%\clone_changes_before_checkout.txt" 2> "%SC_DIR%\backup_errors.txt"
if errorlevel 1 (set "FAILMSG=checkout %SC_REF%: could not list the clone's changes, nothing was touched" & exit /b 1)
git -C "%C%" diff --cached --quiet >> "%SC_DIR%\backup_errors.txt" 2>&1
if errorlevel 1 (
  git -C "%C%" diff --cached --binary > "%SC_DIR%\clone_staged_changes.patch" 2>> "%SC_DIR%\backup_errors.txt"
  set "FAILMSG=checkout %SC_REF%: the clone has staged changes (saved in %SC_DIR%) or git failed; nothing was touched"
  exit /b 1
)
git -C "%C%" diff --binary HEAD > "%SC_DIR%\clone_changes_before_checkout.patch" 2>> "%SC_DIR%\backup_errors.txt"
if errorlevel 1 (set "FAILMSG=checkout %SC_REF%: could not save the patch, nothing was touched" & exit /b 1)
for %%Z in ("%SC_DIR%\clone_changes_before_checkout.txt") do set "SC_LIST=%%~zZ"
for %%Z in ("%SC_DIR%\clone_changes_before_checkout.patch") do set "SC_PATCH=%%~zZ"
if not defined SC_LIST set "SC_LIST=-1"
if not defined SC_PATCH set "SC_PATCH=-1"
if %SC_LIST% LSS 0 (set "FAILMSG=checkout %SC_REF%: the change list was not written, nothing was touched" & exit /b 1)
if %SC_LIST% GTR 0 if %SC_PATCH% LEQ 0 (set "FAILMSG=checkout %SC_REF%: changes are listed but the patch is empty, nothing was touched" & exit /b 1)
git -C "%C%" status --porcelain --untracked-files=no -- . ":(exclude)godot/assets/ships" ":(glob,exclude)godot/**/*.import" > "%SC_DIR%\clone_changes_unexpected.txt" 2>> "%SC_DIR%\backup_errors.txt"
if errorlevel 1 (set "FAILMSG=checkout %SC_REF%: git status of the clone failed, nothing was reset" & exit /b 1)
for %%Z in ("%SC_DIR%\clone_changes_unexpected.txt") do if %%~zZ GTR 0 (set "FAILMSG=checkout %SC_REF%: the clone has local changes outside godot\assets\ships and the .import files, listed in %SC_DIR%; nothing was reset" & exit /b 1)
git -C "%C%" checkout -q HEAD -- godot/assets/ships >> "%SC_DIR%\git.txt" 2>&1
if errorlevel 1 (set "FAILMSG=checkout %SC_REF%: could not restore godot\assets\ships, see %SC_DIR%\git.txt" & exit /b 1)
git -C "%C%" checkout -q HEAD -- ":(glob)godot/**/*.import" >> "%SC_DIR%\git.txt" 2>&1
if errorlevel 1 (set "FAILMSG=checkout %SC_REF%: could not restore the .import files, see %SC_DIR%\git.txt" & exit /b 1)
git -C "%C%" checkout -q --no-overwrite-ignore --detach %SC_REF% >> "%SC_DIR%\git.txt" 2>&1
if errorlevel 1 (set "FAILMSG=checkout %SC_REF% refused, see %SC_DIR%\git.txt; nothing was forced" & exit /b 1)
echo checked out %SC_REF% safely, saved changes in %SC_DIR% >> "%RES%"
exit /b 0
