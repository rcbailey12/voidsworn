@echo off
rem Issue 1262 (PR 1297): cheaper 4K Max, timed and pictured on the RTX 5080. Board queue, GPU solo line (R293).
rem Pinned: NEW = 905cbf3f (opus/issue-1262, main merged in), OLD = main 475b98f5 (after ab6b3258).
rem NEW runs six variants x 3 sessions: after (as shipped), before (VS_1262_OLD=all) and each item put back alone
rem (ssil, underlay, cards, rockshadow); OLD runs main once x 3 sessions. Cases: gate and dense, Max, 1080p and 4K.
rem Then 1070's c170/c26 look shots for NEW (after) and OLD (main).
rem Every Godot start goes through the installed tools_live tmo.bat (fail closed), each in its own throwaway profile;
rem Ryan's real battle_opts.json and board_look.cfg are hashed before and after, a change fails the job.
rem Own clone in Downloads\voidsworn_test\opus1262\repo; built ships copied in from build\godot (copy only, never over
rem a tracked file). Each attempt writes to a new out\run_<stamp>\ folder. Nothing is deleted.
setlocal enabledelayedexpansion
set "NEW=905cbf3f2b5ad78e941bd22b9a5bd92485f9386e"
set "OLD=475b98f53e2c66fadc391e36de016488faf22e30"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus1262"
set "R=%H%\repo"
for /f %%S in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%S"
set "RUN=%H%\out\run_%STAMP%"
if exist "%RUN%" (
  echo FAILED: run folder %RUN% already exists
  exit /b 1
)
mkdir "%RUN%"
set "ST=%RUN%\status.txt"
set "BAD="
echo run1262b start %date% %time% run_%STAMP% > "%ST%"
echo new = %NEW% >> "%ST%"
echo old = %OLD% >> "%ST%"
if "%LB_SHIPS%"=="" set "LB_SHIPS=%VT%\build\godot"
set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
rem The installed watchdog in tools_live: fail closed when tmo.bat or run_timeout.ps1 is missing.
set "TMO="
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if defined TLV if exist "%VT%\tools_live\%TLV%\pc\run_timeout.ps1" if exist "%VT%\tools_live\%TLV%\pc\tmo.bat" set "TMO=%VT%\tools_live\%TLV%\pc\tmo.bat"
if not defined TMO (
  echo FAILED: no tools_live tmo.bat and run_timeout.ps1, tools_live\current.txt = %TLV% >> "%ST%"
  goto fail
)
echo watchdog %TMO% >> "%ST%"
powershell -NoProfile -Command "foreach ($f in '%VT%\tools_live\%TLV%\pc\tmo.bat','%VT%\tools_live\%TLV%\pc\run_timeout.ps1') { (Get-FileHash -Algorithm SHA256 -LiteralPath $f).Hash + ' ' + $f }" >> "%ST%" 2>&1
if errorlevel 1 (echo FAILED: could not hash the watchdog >> "%ST%" & goto fail)
rem Ryan's real options, hashed before anything starts.
set "REALU=%APPDATA%\Godot\app_userdata\Voidsworn"
call :hashes "%RUN%\real_before.txt"
if errorlevel 1 (echo FAILED: could not hash Ryan's real options, nothing was started >> "%ST%" & goto fail)
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%RUN%\git.txt" 2>&1
git -C "%R%" fetch origin main opus/issue-1262 >> "%RUN%\git.txt" 2>&1
if errorlevel 1 (echo FAILED: git fetch, see %RUN%\git.txt >> "%ST%" & goto fail)
git -C "%R%" show %NEW%:contrib/opus/perf_1262/run1262.ps1 > "%RUN%\run1262.ps1"
if errorlevel 1 (echo FAILED: no run1262.ps1 at %NEW% >> "%ST%" & goto fail)
call :one new %NEW% "after=,before=all,ssil=ssil,underlay=underlay,cards=cards,rockshadow=rockshadow"
call :one main %OLD% "main="
call :hashes "%RUN%\real_after.txt"
fc /b "%RUN%\real_before.txt" "%RUN%\real_after.txt" > nul
if errorlevel 1 (
  echo FAILED: Ryan's real options changed during the run, see real_before.txt and real_after.txt >> "%ST%"
  set "BAD=1"
) else (
  echo Ryan's real options unchanged ^(battle_opts.json, board_look.cfg^) >> "%ST%"
)
if defined BAD goto fail
type "%RUN%\out_new\summary_new.txt" >> "%ST%"
type "%RUN%\out_main\summary_main.txt" >> "%ST%"
echo ALL PASS >> "%ST%"
echo run1262b done %date% %time% >> "%ST%"
type "%ST%"
start "" "%RUN%"
exit /b 0
:fail
echo run1262b FAILED %date% %time% >> "%ST%"
type "%ST%"
start "" "%RUN%"
exit /b 1

rem ---- :one NAME SHA VARIANTS: check out, copy ships, import, time and shoot; sets BAD on any failure
:one
set "NAME=%~1"
set "SHA=%~2"
set "VARS=%~3"
set "O=%RUN%\out_%NAME%"
mkdir "%O%"
git -C "%R%" checkout -f --detach %SHA% >> "%RUN%\git.txt" 2>&1
if errorlevel 1 (echo FAILED: %NAME% cannot check out %SHA% >> "%ST%" & set "BAD=1" & exit /b 1)
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt"
set "RCX=/E /XC /XN /XO /XF manifest.json README.md a4_props.gd *.uid /NFL /NDL /NJH /NJS /R:1 /W:1"
if exist "%LB_SHIPS%\gen" robocopy "%LB_SHIPS%\gen" "%R%\godot\gen" %RCX% > nul 2>&1
if exist "%LB_SHIPS%\assets\ships" robocopy "%LB_SHIPS%\assets\ships" "%R%\godot\assets\ships" %RCX% > nul 2>&1
if not exist "%R%\godot\.godot" if exist "%LB_SHIPS%\.godot" robocopy "%LB_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
rem No tracked .gd may differ from the pinned commit after the copies (a stale a4_props.gd broke a run on Nov 19).
git -C "%R%" status --porcelain --untracked-files=no -- "*.gd" > "%O%\tracked_gd_changes.txt"
for %%A in ("%O%\tracked_gd_changes.txt") do if %%~zA GTR 0 (
  echo FAILED: %NAME% tracked .gd files changed by the ship copy, see %O%\tracked_gd_changes.txt >> "%ST%"
  set "BAD=1"
  exit /b 1
)
set "P=%O%\profile_import"
mkdir "%P%"
set "OLDAPP=%APPDATA%"
set "OLDLOC=%LOCALAPPDATA%"
set "APPDATA=%P%"
set "LOCALAPPDATA=%P%"
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
set "IMPEL=%errorlevel%"
set "APPDATA=%OLDAPP%"
set "LOCALAPPDATA=%OLDLOC%"
if not "%IMPEL%"=="0" (echo FAILED: %NAME% import, see %O%\import.txt >> "%ST%" & set "BAD=1" & exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -File "%RUN%\run1262.ps1" -Work "%R%" -Tmo "%TMO%" -Godot "%G%" -Out "%O%" -Label %NAME% -Variants "%VARS%" -ShotVariant "" > "%O%\log.txt" 2>&1
if errorlevel 1 (echo FAILED: %NAME% timing or shots, see %O%\log.txt >> "%ST%" & set "BAD=1" & exit /b 1)
echo %NAME% %SHA% timed and shot >> "%ST%"
exit /b 0

rem ---- :hashes FILE
:hashes
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%~1" 2>&1
exit /b %errorlevel%
