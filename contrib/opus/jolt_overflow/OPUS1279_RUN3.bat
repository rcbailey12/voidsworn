@echo off
title Opus 1279 run 3: Jolt job overflow on capital arrival, before and after - GPU job
rem Issue 1279: on 1232 RUN4, plain main's "before s2 arrival" logged "Jolt Physics job system exceeded the maximum number
rem of jobs" and run_timeout stopped Godot. This runs the same arrival bench (contrib/opus/cold_kill_1232/capture1232.gd:
rem warm-up at load with only the shooter, then A16 arrives and is killed 6 frames later) five times on current main
rem (BEFORE) and five times on the fix (AFTER), each session in its own empty profile (a first session's empty shader
rem cache, the heaviest compile storm). run_timeout stops any Godot that logs the Jolt warning, so a hit shows as a
rem nonzero exit and a "FATAL Jolt" line. It also runs the headless check fx/test/jolt_jobs_check.gd on the fix, which
rem prints this PC's lane budget.
rem PASSED needs: the jolt_jobs_check passes, all 5 AFTER arrival rows collected, and no "job system exceeded" in any AFTER
rem log. BEFORE rows are evidence only (the overflow is intermittent: 1 of 3 on RUN4).
rem Its own sparse clone in opus1279\repo (godot, tools, contrib\opus\cold_kill_1232; made on the first run). Ryan's real
rem battle_opts.json and board_look.cfg are hashed before and after. Writes only under opus1279\. Never deletes anything.
rem Run 2 (Board, Nov 20): every Godot start goes through the installed watchdog tools_live\<current.txt>\pc\tmo.bat (fails
rem closed if it or run_timeout.ps1 is missing; path and SHA256 in result.txt); the ships copy leaves out manifest.json,
rem README.md, a4_props.gd, *.uid, test and previews, and the run stops if any tracked .gd in the clone then differs.
rem Run 1's bat (Artoo on PR 1302) had duplicate :one_commit and :realcheck labels; this file has one of each.
rem Run 3 (replaces run 2): the same job pinned to the fix merged with main after PR 1255 (issue 1237), against that main.
rem Logs to out_<A>\result.txt and ends with "all done".
setlocal EnableDelayedExpansion
set AFTER=ef0c138dd22ecbe10f48433ebe07f92907bb8aab
set BEFORE=eb23594d290d1a7d7e32281b94f6545394ef2a90
set CAPREF=eb23594d290d1a7d7e32281b94f6545394ef2a90
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1279
set C=%W%\repo
if not exist "%W%" mkdir "%W%"
set A=1
:findattempt
if exist "%W%\out_%A%" (set /a A+=1 & goto findattempt)
set O=%W%\out_%A%
mkdir "%O%"
set RES=%O%\result.txt
set GOOD=0
set HITS_AFTER=0
set HITS_BEFORE=0
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
rem the canonical watchdog: tools_live's current version, never the clone's own copy
set "TLV="
if exist "%V%\tools_live\current.txt" set /p TLV=<"%V%\tools_live\current.txt"
if not defined TLV (set "FAILMSG=tools_live\current.txt is missing or empty" & goto fail)
set "TM=%V%\tools_live\%TLV%\pc\tmo.bat"
if not exist "%TM%" (set "FAILMSG=no watchdog at %TM%" & goto fail)
if not exist "%V%\tools_live\%TLV%\pc\run_timeout.ps1" (set "FAILMSG=no run_timeout.ps1 beside %TM%" & goto fail)
echo watchdog %TM% >> "%RES%"
certutil -hashfile "%TM%" SHA256 >> "%RES%" 2>&1
certutil -hashfile "%V%\tools_live\%TLV%\pc\run_timeout.ps1" SHA256 >> "%RES%" 2>&1
set PC_GPU_WAIT_SECONDS=3600
set PC_GPU_ISSUE=1279
"%GD%" --version >> "%RES%" 2>&1
for %%K in (after before) do (
  set "WHICH=%%K"
  call :one_commit
  if errorlevel 1 goto fail
)
set PC_GPU_MODE=
echo after arrival rows collected !GOOD! of 5 >> "%RES%"
echo logs with the Jolt warning: after !HITS_AFTER! of 5, before !HITS_BEFORE! of 5 (before is evidence only) >> "%RES%"
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
if not "!GOOD!"=="5" (set "FAILMSG=only !GOOD! of 5 after arrival rows were collected" & goto fail)
if not "!HITS_AFTER!"=="0" (set "FAILMSG=the fix still logged the Jolt warning in !HITS_AFTER! of 5 sessions" & goto fail)
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
robocopy "%V%\build\godot\assets\ships" "%C%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NP > "%OK%\log_copy_ships.txt" 2>&1
set E=%ERRORLEVEL%
echo copy ships robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (set "FAILMSG=copy ships failed" & exit /b 1)
if exist "%V%\build\godot\gen" robocopy "%V%\build\godot\gen" "%C%\godot\gen" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NP > "%OK%\log_copy_gen.txt" 2>&1
set E=%ERRORLEVEL%
echo copy gen robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (set "FAILMSG=copy gen failed" & exit /b 1)
rem a stale copied script must never run (Board, Nov 20): stop if any tracked .gd now differs from the commit
git -C "%C%" status --porcelain --untracked-files=no -- "*.gd" > "%OK%\tracked_gd_changes.txt" 2>&1
if errorlevel 1 (set "FAILMSG=git status of the clone failed after the ships copy" & exit /b 1)
for %%Z in ("%OK%\tracked_gd_changes.txt") do if %%~zZ GTR 0 (set "FAILMSG=tracked .gd files changed after the ships copy, listed in %OK%\tracked_gd_changes.txt" & exit /b 1)
echo %WHICH% no tracked .gd changed by the copy >> "%RES%"
if not exist "%C%\godot\bench\opus1232" mkdir "%C%\godot\bench\opus1232"
rem the same capture both times (main's copy; the fix does not change it)
git -C "%C%" show %CAPREF%:contrib/opus/cold_kill_1232/capture1232.gd > "%C%\godot\bench\opus1232\capture1232.gd" 2>> "%RES%"
if errorlevel 1 (
  git -C "%C%" fetch -q --depth 1 origin %CAPREF% >> "%RES%" 2>&1
  git -C "%C%" show %CAPREF%:contrib/opus/cold_kill_1232/capture1232.gd > "%C%\godot\bench\opus1232\capture1232.gd" 2>> "%RES%"
  if errorlevel 1 (set "FAILMSG=could not write the capture script" & exit /b 1)
)
cd /d "%C%"
set "APPDATA=%PROF%\import_%WHICH%"
set "LOCALAPPDATA=%PROF%\import_%WHICH%"
mkdir "%APPDATA%"
call "%TM%" 3600 "%GD%" --headless --path "%C%\godot" --import > "%OK%\log_import.txt" 2>&1
set E=%ERRORLEVEL%
echo %WHICH% import exit %E% >> "%RES%"
if not "%E%"=="0" (set "FAILMSG=%WHICH% import failed" & exit /b 1)
if "%WHICH%"=="after" (
  call "%TM%" 600 "%GD%" --headless --path "%C%\godot" --script res://fx/test/jolt_jobs_check.gd > "%OK%\log_jolt_jobs_check.txt" 2>&1
  set E=!ERRORLEVEL!
  echo jolt jobs check exit !E! >> "%RES%"
  findstr /c:"JOLT_JOBS" "%OK%\log_jolt_jobs_check.txt" >> "%RES%" 2>nul
  if not "!E!"=="0" (set "FAILMSG=jolt jobs check failed" & exit /b 1)
)
rem frame times, solo on the GPU (R293): five arrival sessions, each in its own process and its own empty profile
set PC_GPU_MODE=solo
for %%N in (1 2 3 4 5) do (
  mkdir "%OK%\s%%N" 2>nul
  set "APPDATA=%PROF%\%WHICH%_s%%N"
  set "LOCALAPPDATA=%PROF%\%WHICH%_s%%N"
  mkdir "!APPDATA!"
  call "%TM%" 1800 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1232/capture1232.gd -- arrival "%OK%\s%%N" > "%OK%\s%%N\log_arrival.txt" 2>&1
  set E=!ERRORLEVEL!
  echo %WHICH% s%%N arrival exit !E! >> "%RES%"
  findstr /i /c:"job system exceeded" "%OK%\s%%N\log_arrival.txt" >nul 2>&1 && (
    echo %WHICH% s%%N: Jolt job table warning >> "%RES%"
    if "%WHICH%"=="after" (set /a HITS_AFTER+=1) else (set /a HITS_BEFORE+=1)
  )
  if "%WHICH%"=="after" if "!E!"=="0" findstr /c:"\"outcome\"" "%OK%\s%%N\arrival.json" >nul 2>&1 && set /a GOOD+=1
  findstr /c:"CAPTURE1232 arrival" "%OK%\s%%N\log_arrival.txt" >> "%RES%" 2>nul
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
