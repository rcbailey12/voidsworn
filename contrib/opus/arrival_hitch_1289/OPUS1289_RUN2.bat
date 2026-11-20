@echo off
title Opus 1289 run 2: a ship arriving mid-battle, before and after - GPU job
rem Run 2 (Board, Nov 20): the ships copy skips manifest.json, README.md, a4_props.gd, *.uid, test and previews, and the
rem run stops if any tracked .gd in the clone changed after the copies (both commits). Otherwise the same as run 1.
rem Issue 1289: a capital arriving after the load cost about 1 s in one frame (1232 run 4: 845 to 998 ms, all on the main
rem thread, GPU under 8 ms). This names the cost and proves the fix (the battle builds, cuts and draws its reinforcement's
rem hull under the loading cover, render/arrival_warm.gd, then keeps it hidden until it arrives).
rem Each row is a fresh process in its own empty throwaway profile (no shader or shield cache, as a first session), two
rem sessions each, on the fix (AFTER) and on main (BEFORE), frames paced to 60 a second, solo on the GPU:
rem   arrival    load with the shooter only, then the hull arrives (built in the arrival frame, timed in parts) and is
rem              killed 6 frames later
rem   again      the same hull arrives a second time in the same process (what is first-sight-only)
rem   prewarmed  the battle's fix: the load also builds the arriving hull through the kit (skipped on BEFORE, no kit)
rem   firstkill  the hull is on the board at the load; killed after 60 frames of play (the first kill after a normal load)
rem   cold       nothing warmed at all (the bench-only case; every battle warms under its loading cover)
rem Hulls: A16 (c_boss, C19_51, the capital of issue 1232) for every mode; warden (the Sunward garrison frigate, the hull a
rem real reinforcement brings: the rules send their faction's cheapest hull) for arrival and prewarmed.
rem Every Godot start goes through the canonical watchdog tools_live\<current>\pc\tmo.bat (its path and hashes in the
rem receipt), never the pinned clone's own. Ryan's real battle_opts.json and board_look.cfg are hashed before the first
rem Godot start and at the end (and on any stop); a difference is FAILED. Start it after any frame-time job holding the
rem GPU; it waits up to an hour per GPU claim. Its own sparse clone in opus1289\repo (godot, tools, contrib\opus\arrival_hitch_1289).
rem Writes only under opus1289\ (out_<A>, A the first unused attempt number). Never deletes anything.
rem PASSED needs the six named AFTER rows (prewarmed c_boss, prewarmed warden, firstkill c_boss; two sessions each) present,
rem with no frame over 100 ms and a kill that broke into pieces (Artoo on PR 1293). Every other row is a diagnostic: shown
rem in the table, a missing or aborted one listed (MISSING lines), never failing the run. Ends with "all done".
setlocal EnableDelayedExpansion
set AFTER=52f7d10b0cb647b468b55c5b0075806d19d136c3
set BEFORE=ab6b3258965d05f745e8897fc7219c9775580ace
rem the capture is unchanged since AFTER; CAPREF also carries run 2's summary gate (game code identical to AFTER)
set CAPREF=1dfa85a773d11d33643a40d00086faabecb5065f
set ROWS=28
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1289
set C=%W%\repo
if not exist "%W%" mkdir "%W%"
set A=1
:findattempt
if exist "%W%\out_%A%" (set /a A+=1 & goto findattempt)
set O=%W%\out_%A%
mkdir "%O%"
set RES=%O%\result.txt
set GOOD=0
echo start %DATE% %TIME% attempt %A% > "%RES%"
findstr /b /c:"GPU cleared" "%V%\gpu_go.txt" >nul 2>&1 || (echo gpu_go.txt is not GPU cleared: stopped >> "%RES%" & echo all done >> "%RES%" & exit /b 0)
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
if not exist "%C%\.git" (
  git clone -q --filter=blob:none --no-checkout --depth 1 https://github.com/rcbailey12/voidsworn.git "%C%" >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=git clone failed" & goto fail)
  git -C "%C%" sparse-checkout set godot tools contrib/opus/arrival_hitch_1289 >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=sparse-checkout failed" & goto fail)
  git -C "%C%" checkout -q main >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=first checkout of the sparse clone failed" & goto fail)
  echo made the sparse clone >> "%RES%"
)
rem the capture and the summary come from CAPREF, kept outside the clone (the before commit does not have them)
git -C "%C%" fetch -q --depth 1 origin %CAPREF% >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=git fetch of %CAPREF% failed" & goto fail)
git -C "%C%" show %CAPREF%:contrib/opus/arrival_hitch_1289/capture1289.gd > "%O%\capture1289.gd" 2>> "%RES%"
if errorlevel 1 (set "FAILMSG=could not write the capture script" & goto fail)
git -C "%C%" show %CAPREF%:contrib/opus/arrival_hitch_1289/summary1289.ps1 > "%O%\summary1289.ps1" 2>> "%RES%"
if errorlevel 1 (set "FAILMSG=could not write the summary script" & goto fail)
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
rem the canonical watchdog: tools_live's current version (named in tools_live\current.txt), never the pinned clone's own
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
set PC_GPU_ISSUE=1289
"%GD%" --version >> "%RES%" 2>&1
for %%K in (after before) do (
  set "WHICH=%%K"
  call :one_commit
  if errorlevel 1 goto fail
)
set PC_GPU_MODE=
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%REAL_LOCALAPPDATA%"
echo rows collected !GOOD! of %ROWS% (diagnostic rows may be missing; only the six gated after rows must pass) >> "%RES%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%O%\summary1289.ps1" -Out "%O%" > "%O%\summary.txt" 2>&1
set ACC=!ERRORLEVEL!
type "%O%\summary.txt" >> "%RES%"
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
rem Artoo on PR 1293: only the six named AFTER rows gate the run; a missing diagnostic row is listed above, not a failure
if not "!ACC!"=="0" (set "FAILMSG=a gated after row (prewarmed c_boss, prewarmed warden, firstkill c_boss, both sessions) is missing, over 100 ms or without pieces (see the gate and ACCEPT lines)" & goto fail)
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
robocopy "%V%\build\godot\assets\ships" "%C%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NP > "%OK%\log_copy_ships.txt" 2>&1
set E=%ERRORLEVEL%
echo copy ships robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (set "FAILMSG=copy ships failed" & exit /b 1)
if exist "%V%\build\godot\gen" robocopy "%V%\build\godot\gen" "%C%\godot\gen" /E /NFL /NDL /NJH /NP > "%OK%\log_copy_gen.txt" 2>&1
set E=%ERRORLEVEL%
echo copy gen robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (set "FAILMSG=copy gen failed" & exit /b 1)
rem run 2 (Board, Nov 20): the copies must not change any tracked game script (1236 RUN3 lost a4_props.gd to a stale copy)
git -C "%C%" status --porcelain --untracked-files=no -- "*.gd" > "%OK%\tracked_gd_changes.txt" 2>&1
if errorlevel 1 (set "FAILMSG=%WHICH%: git status after the copies failed" & exit /b 1)
for %%Z in ("%OK%\tracked_gd_changes.txt") do if %%~zZ GTR 0 (set "FAILMSG=%WHICH%: the copies changed tracked .gd files, listed in %OK%\tracked_gd_changes.txt" & exit /b 1)
echo %WHICH% tracked .gd files unchanged after the copies >> "%RES%"
if not exist "%C%\godot\bench\opus1289" mkdir "%C%\godot\bench\opus1289"
copy /y "%O%\capture1289.gd" "%C%\godot\bench\opus1289\capture1289.gd" > nul
if errorlevel 1 (set "FAILMSG=copying the capture script failed" & exit /b 1)
cd /d "%C%"
set "APPDATA=%PROF%\import_%WHICH%"
set "LOCALAPPDATA=%PROF%\import_%WHICH%"
mkdir "%APPDATA%"
call "%TM%" 3600 "%GD%" --headless --path "%C%\godot" --import > "%OK%\log_import.txt" 2>&1
set E=%ERRORLEVEL%
echo %WHICH% import exit %E% >> "%RES%"
if not "%E%"=="0" (set "FAILMSG=%WHICH% import failed" & exit /b 1)
if "%WHICH%"=="after" (
  call "%TM%" 600 "%GD%" --headless --path "%C%\godot" --script res://render/test/arrival_warm_check.gd > "%OK%\log_arrival_warm_check.txt" 2>&1
  set E=!ERRORLEVEL!
  echo arrival warm check exit !E! >> "%RES%"
  if not "!E!"=="0" (set "FAILMSG=arrival warm check failed" & exit /b 1)
  call "%TM%" 600 "%GD%" --headless --path "%C%\godot" --script res://rules/test/arrival_preview_test.gd > "%OK%\log_arrival_preview_test.txt" 2>&1
  set E=!ERRORLEVEL!
  echo arrival preview test exit !E! >> "%RES%"
  if not "!E!"=="0" (set "FAILMSG=arrival preview test failed" & exit /b 1)
)
rem frame times, solo on the GPU (R293): two sessions, each mode and hull in its own process and its own empty profile
set PC_GPU_MODE=solo
for %%N in (1 2) do (
  mkdir "%OK%\s%%N" 2>nul
  call :row %%N arrival c_boss
  call :row %%N again c_boss
  call :row %%N prewarmed c_boss
  call :row %%N firstkill c_boss
  call :row %%N cold c_boss
  call :row %%N arrival warden
  call :row %%N prewarmed warden
)
set PC_GPU_MODE=
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%REAL_LOCALAPPDATA%"
exit /b 0

rem ---------------------------------------------------------------- :row SESSION MODE HULL (one fresh process, one empty profile)
:row
set "APPDATA=%PROF%\%WHICH%_s%1_%2_%3"
set "LOCALAPPDATA=%PROF%\%WHICH%_s%1_%2_%3"
mkdir "%APPDATA%"
call "%TM%" 1800 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1289/capture1289.gd -- %2 "%OK%\s%1" %3 > "%OK%\s%1\log_%2_%3.txt" 2>&1
set E=%ERRORLEVEL%
echo %WHICH% s%1 %2 %3 exit %E% >> "%RES%"
if "%E%"=="0" findstr /c:"\"mode\"" "%OK%\s%1\%2_%3.json" >nul 2>&1 && set /a GOOD+=1
findstr /c:"CAPTURE1289 %2" "%OK%\s%1\log_%2_%3.txt" >> "%RES%" 2>nul
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
