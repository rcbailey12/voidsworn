@echo off
rem Look bench (issue 351): double-click to make the look bench sheets on this PC.
rem   look_bench.bat                  bench the newest main and compare it with the accepted baseline (docs\shots\look_bench\BASELINE.txt)
rem   look_bench.bat AFTER            bench AFTER (a commit, branch or origin/branch) and compare it with the baseline
rem   look_bench.bat AFTER BEFORE     bench both and compare them side by side (BEFORE "none": AFTER's sheets only)
rem   add "go" as a third word to wait for Downloads\voidsworn_test\look_bench\go.txt first (the Board's GPU window file)
rem Each commit is benched once (runs\<commit>\, reused next time). Sheets land in sheets\<before>_vs_<after>\ and the
rem folder opens when it is done. Nothing on the PC is deleted. The watchdog takes a shared GPU
rem claim for each capture run and obeys gpu_go.txt. Frame-time measurements take solo.
rem Settings a job may set first (all optional):
rem   LB_HOME      the bench folder (default Downloads\voidsworn_test\look_bench)
rem   LB_TOOL_REF  where the bench script itself comes from (default origin/main): the bench runs from that version on
rem                every commit, so commits made before the bench existed can be benched too
rem   LB_ARGS      extra bench words, e.g. --part moments --moments res://bench/look_moments_acid_thorn.json (issue 1877)
rem   LB_MOMENTS   full path to a rows file, runs only those moments on both revisions (overrides LB_ARGS)
rem   LB_SHIPS     a godot folder that has the PC-built hulls (gen, assets\ships, .godot) to copy from (copy only)
rem   LB_PRE_RUN   a .bat called with the game checkout's folder after checkout (bench proofs: change one number)
rem   LB_RUN_NAME  the run folder name for AFTER instead of its commit (use with LB_PRE_RUN)
rem   LB_QUIET     1: do not open the sheets folder at the end
rem   LB_MOMENTS   full path to a job rows file. Both revisions run those moments only.
rem   LB_SHEETS    optional parent folder for the revision-labelled sheets
rem Issue 1194: every step runs through job_wrap.bat (the installed main watchdog in tools_live, a GPU label on each claim,
rem PC_GPU_ISSUE, default look_bench). Godot and a Python with Pillow are checked before any clone; a failed step stops it.
rem LB_HOME\done.txt says PASS or FAILED: <steps> and the exit code is 0 only on PASS.
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
if "%LB_HOME%"=="" set "LB_HOME=%VT%\look_bench"
if "%LB_TOOL_REF%"=="" set "LB_TOOL_REF=origin/main"
if "%LB_SHEETS%"=="" set "LB_SHEETS=%LB_HOME%\sheets"
if not defined LB_MOMENTS goto rows_ok
if not exist "%LB_MOMENTS%" (
  echo FAILED: look bench rows file missing: "%LB_MOMENTS%"
  exit /b 2
)
set LB_ARGS=--part moments --moments "%LB_MOMENTS%"
:rows_ok
rem Built ships: the shared PC build (build\godot), else the old audit2 checkout. LB_SHIPS overrides both (issue 1223).
if "%LB_SHIPS%"=="" if exist "%VT%\build\godot\gen" set "LB_SHIPS=%VT%\build\godot"
if "%LB_SHIPS%"=="" set "LB_SHIPS=%VT%\audit2\repo\godot"
set "AFTER=%~1"
set "BEFORE=%~2"
set "GOWAIT=%~3"
if "%AFTER%"=="" set "AFTER=origin/main"
if not exist "%LB_HOME%" mkdir "%LB_HOME%"
set "ST=%LB_HOME%\status.txt"
echo look bench start %date% %time% after=%AFTER% before=%BEFORE% > "%ST%"
if not defined PC_GPU_ISSUE set "PC_GPU_ISSUE=look_bench"
set "JW=%~dp0..\job_wrap.bat"
call "%JW%" init "%LB_HOME%" "%PC_GPU_ISSUE%" "godot pil"
if errorlevel 1 exit /b %ERRORLEVEL%
set "G=%JW_GODOT%"
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $id=[guid]::NewGuid().ToString('N'); $dir=Join-Path $env:TEMP ('voidsworn-run-' + $id); $null=[IO.Directory]::CreateDirectory($dir); [IO.File]::WriteAllText((Join-Path $dir '.voidsworn-run-owner'),$id); $dir" > "%LB_HOME%\scratch_path.txt" 2>> "%ST%"
if errorlevel 1 (
  echo FAILED: private TEMP setup >> "%ST%"
  call "%JW%" fail "private TEMP setup"
  goto finish
)
set "BASE_TEMP=%TEMP%"
set /p TEMP=<"%LB_HOME%\scratch_path.txt"
set "TMP=%TEMP%"
set "TMPDIR=%TEMP%"
rem (1535) Python tools make their temporary folders with inherited ACLs (tools\pc\pysite\sitecustomize.py), so the
rem scratch cleanup can remove them; mkdtemp on Python 3.12.4+ for Windows made private folders it could not delete.
set "BASE_PYTHONPATH=%PYTHONPATH%"
if defined PYTHONPATH set "PYTHONPATH=%~dp0..\pysite;%PYTHONPATH%"
if not defined PYTHONPATH set "PYTHONPATH=%~dp0..\pysite"
rem The redirection holds the marker open until the tools finish (every step below, through job_wrap end).
call :run_tools 9>"%TEMP%\.voidsworn-run-active"
set "RUN_EL=%ERRORLEVEL%"
rem (1180) The scratch goes on PASS; on FAILED the newest one per bench home stays a day (scratch_done.ps1 beside job_wrap).
set "RUN_SCRATCH=%TEMP%"
set "TEMP=%BASE_TEMP%"
set "TMP=%BASE_TEMP%"
set "TMPDIR=%BASE_TEMP%"
set "PYTHONPATH=%BASE_PYTHONPATH%"
if exist "%~dp0..\scratch_done.ps1" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scratch_done.ps1" -Scratch "%RUN_SCRATCH%" -Code %RUN_EL% -BaseTemp "%BASE_TEMP%" -JobKey "look_bench %LB_HOME%" >> "%ST%" 2>&1
exit /b %RUN_EL%

:run_tools

if /i not "%GOWAIT%"=="go" goto gook
echo waiting for %VT%\look_bench\go.txt >> "%ST%"
:gowait
if exist "%VT%\look_bench\go.txt" goto gook
timeout /t 60 /nobreak > nul
goto gowait
:gook

rem ---- seed local checkouts once under the mirror lock, then fetch just the requested pins without it
set "TOOL=%LB_HOME%\tool"
set "R=%LB_HOME%\repo"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\runner_common.ps1" look-bench-checkout "%TEMP%\look_bench_pins.txt" > "%LB_HOME%\git_tool.txt" 2>&1
if errorlevel 1 (
  echo FAILED: bench pin setup, see git_tool.txt >> "%ST%"
  call "%JW%" fail "bench pin setup"
  goto finish
)
if not exist "%TOOL%\godot\bench\look_bench.gd" (
  echo FAILED: no bench script at %LB_TOOL_REF% >> "%ST%"
  echo FAILED: no bench script at %LB_TOOL_REF%
  call "%JW%" fail "no bench script"
  goto finish
)
for /f "usebackq tokens=1,2" %%A in ("%TEMP%\look_bench_pins.txt") do (
  set "AFTER_PIN=%%A"
  set "BEFORE_PIN=%%B"
)

set "RUN_A="
set "RUN_B="
call :bench "%AFTER_PIN%" "%LB_RUN_NAME%" "%LB_PRE_RUN%"
if errorlevel 1 goto finish
set "RUN_A=%RUNDIR%"
set "NAME_A=%RUNNAME%"
set "LABEL_A=%SHA%"
if /i "%BEFORE_PIN%"=="none" goto sheets
call :bench "%BEFORE_PIN%" "" ""
if errorlevel 1 goto finish
set "RUN_B=%RUNDIR%"
set "NAME_B=%RUNNAME%"
set "LABEL_B=%SHA%"

:sheets
rem ---- the sheet maker needs Python with Pillow: the preflight found one (JW_PIL) before anything ran
set "PY=%JW_PIL%"
if "%RUN_B%"=="" (
  set "S=%LB_SHEETS%\%NAME_A%"
  set "SARGS=--after "%RUN_A%" --out "!S!" --label-after %LABEL_A%"
) else (
  set "S=%LB_SHEETS%\%NAME_B%_vs_%NAME_A%"
  set "SARGS=--after "%RUN_A%" --before "%RUN_B%" --out "!S!" --label-after %LABEL_A% --label-before %LABEL_B%"
)
if not exist "%S%" mkdir "%S%"
set "JW_STEP=sheets" & call "%JW%" run 1800 "%PY%" "%TOOL%\tools\pc\jobs\look_bench_sheets.py" %SARGS% > "%S%\sheets_log.txt" 2>&1
if errorlevel 1 goto finish
echo sheets exit %ERRORLEVEL% %date% %time% %S% >> "%ST%"
if exist "%S%\summary.txt" type "%S%\summary.txt"
if not "%LB_QUIET%"=="1" start "" explorer "%S%"

:finish
echo look bench done %date% %time% >> "%ST%"
rem done PASS or done FAILED: <steps>, then all done, in status.txt and done.txt; the exit code follows.
call "%JW%" end
exit /b %ERRORLEVEL%

rem ---------------------------------------------------------------- one bench run: :bench REF [RUNNAME] [PRE_RUN]
:bench
set "REF=%~1"
set "RUNNAME=%~2"
set "PRE=%~3"
call :checkout "%R%" "%REF%" >> "%LB_HOME%\git_repo.txt" 2>&1
if errorlevel 1 (
  echo FAILED: cannot check out %REF% >> "%ST%"
  echo FAILED: cannot check out %REF%
  call "%JW%" fail "checkout %REF%"
  exit /b 1
)
for /f %%H in ('git -C "%R%" rev-parse --short^=8 HEAD') do set "SHA=%%H"
if "%RUNNAME%"=="" set "RUNNAME=%SHA%"
if defined LB_MOMENTS (
  set "LB_ROWS_KEY="
  for /f %%H in ('git hash-object "%LB_MOMENTS%"') do set "LB_ROWS_KEY=%%H"
  set "LB_TOOL_SHA="
  for /f %%H in ('git -C "%TOOL%" rev-parse --short^=8 HEAD') do set "LB_TOOL_SHA=%%H"
  if not defined LB_ROWS_KEY (
    call "%JW%" fail "cannot hash custom rows"
    exit /b 1
  )
  if not defined LB_TOOL_SHA (
    call "%JW%" fail "cannot read bench tool revision"
    exit /b 1
  )
  set "RUNNAME=!RUNNAME!_!LB_TOOL_SHA!_!LB_ROWS_KEY:~0,8!"
)
set "RUNDIR=%LB_HOME%\runs\%RUNNAME%"
if exist "%RUNDIR%\DONE.txt" (
  echo reuse %RUNDIR% >> "%ST%"
  exit /b 0
)
if not exist "%RUNDIR%" mkdir "%RUNDIR%"
git -C "%R%" log -1 --format=%%H > "%RUNDIR%\commit.txt"
rem the PC-built hulls and the import cache a fresh clone lacks (copy only, never over newer files)
if exist "%LB_SHIPS%\gen" robocopy "%LB_SHIPS%\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%RUNDIR%\copy_gen.txt" 2>&1
if exist "%LB_SHIPS%\assets\ships" robocopy "%LB_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%RUNDIR%\copy_ships.txt" 2>&1
if not exist "%R%\godot\.godot" if exist "%LB_SHIPS%\.godot" robocopy "%LB_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%RUNDIR%\copy_cache.txt" 2>&1
rem the bench itself comes from the tool checkout, so any commit can be benched
if not exist "%R%\godot\bench" mkdir "%R%\godot\bench"
copy /y "%TOOL%\godot\bench\look_bench.gd" "%R%\godot\bench\look_bench.gd" > nul
copy /y "%TOOL%\godot\bench\look_bench.tscn" "%R%\godot\bench\look_bench.tscn" > nul
copy /y "%TOOL%\godot\bench\look_moments*.json" "%R%\godot\bench\" > nul
rem The current capture tool stamps the game checkout's revision, including older baselines.
if not exist "%R%\godot\tools" mkdir "%R%\godot\tools"
copy /y "%TOOL%\godot\tools\picture_provenance.gd" "%R%\godot\tools\picture_provenance.gd" > nul
set "PICTURE_STAMP_TOOL=%TOOL%\tools\picture_provenance.py"
set "PICTURE_SOURCE_REPO=%R%"
if not "%PRE%"=="" call "%PRE%" "%R%" > "%RUNDIR%\pre_run.txt" 2>&1
set "JW_STEP=import %SHA%" & call "%JW%" run 1800 "%G%" --headless --path "%R%\godot" --import > "%RUNDIR%\import.txt" 2>&1
if errorlevel 1 exit /b 1
echo imported %REF% %SHA% %date% %time% >> "%ST%"
rem R276: tmo claims a shared slot for these stills; timing scripts claim solo automatically.
set "JW_STEP=bench %SHA%" & set "JW_EXPECT=%RUNDIR%\bench.json" & call "%JW%" run 3600 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%RUNDIR%" --commit %SHA% %LB_ARGS% > "%RUNDIR%\bench_log.txt" 2>&1
set "BX=%ERRORLEVEL%"
if not "%BX%"=="0" exit /b 1
echo bench exit %BX% %REF% %date% %time% >> "%ST%"
rem put the checkout back as the commit has it (the bench files copied in are not part of it)
git -C "%R%" checkout -f --detach %SHA% > nul 2>&1
findstr /c:"LOOK_BENCH placeholder hull" "%RUNDIR%\bench_log.txt" > nul
if not errorlevel 1 (
  echo placeholder hull: STOPPED, %REF% draws a block instead of a ship. Copy the built hulls in, see %RUNDIR%\PLACEHOLDER.txt >> "%ST%"
  echo placeholder hull
  echo STOPPED: %REF% would draw a block instead of a ship. See %RUNDIR%\PLACEHOLDER.txt
  call "%JW%" fail "placeholder hull in %SHA%"
  exit /b 1
)
findstr /c:"LOOK_BENCH_DONE" "%RUNDIR%\bench_log.txt" > nul
if errorlevel 1 (
  echo FAILED: the bench did not finish for %REF%, see %RUNDIR%\bench_log.txt >> "%ST%"
  echo FAILED: the bench did not finish for %REF%
  call "%JW%" fail "bench %SHA% did not finish"
  exit /b 1
)
if defined LB_MOMENTS (
  findstr /c:"SCRIPT ERROR" /c:"LOOK_BENCH CODE MISMATCH" /c:"a window never opened" "%RUNDIR%\bench_log.txt" > nul
  if not errorlevel 1 (
    call "%JW%" fail "capture errors in %SHA%; see bench_log.txt"
    exit /b 1
  )
)
echo %SHA% > "%RUNDIR%\DONE.txt"
exit /b 0

:checkout
git -C "%~1" checkout -f --detach "%~2"
exit /b %ERRORLEVEL%
