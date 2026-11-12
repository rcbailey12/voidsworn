@echo off
rem Look bench (issue 351): double-click to make the look bench sheets on this PC.
rem   look_bench.bat                  bench the newest main and compare it with the accepted baseline (docs\shots\look_bench\BASELINE.txt)
rem   look_bench.bat AFTER            bench AFTER (a commit, branch or origin/branch) and compare it with the baseline
rem   look_bench.bat AFTER BEFORE     bench both and compare them side by side (BEFORE "none": AFTER's sheets only)
rem   add "go" as a third word to wait for Downloads\voidsworn_test\look_bench\go.txt first (the Board's GPU window file)
rem Each commit is benched once (runs\<commit>\, reused next time). Sheets land in sheets\<before>_vs_<after>\ and the
rem folder opens when it is done. Nothing on the PC is deleted. One GPU job at a time: waits (up to 60 minutes) until the
rem graphics card is idle before each bench run.
rem Settings a job may set first (all optional):
rem   LB_HOME      the bench folder (default Downloads\voidsworn_test\look_bench)
rem   LB_TOOL_REF  where the bench script itself comes from (default origin/main): the bench runs from that version on
rem                every commit, so commits made before the bench existed can be benched too
rem   LB_SHIPS     a godot folder that has the PC-built hulls (gen, assets\ships, .godot) to copy from (copy only)
rem   LB_PRE_RUN   a .bat called with the game checkout's folder after checkout (bench proofs: change one number)
rem   LB_RUN_NAME  the run folder name for AFTER instead of its commit (use with LB_PRE_RUN)
rem   LB_QUIET     1: do not open the sheets folder at the end
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
if "%LB_HOME%"=="" set "LB_HOME=%VT%\look_bench"
if "%LB_TOOL_REF%"=="" set "LB_TOOL_REF=origin/main"
if "%LB_SHIPS%"=="" set "LB_SHIPS=%VT%\audit2\repo\godot"
set "AFTER=%~1"
set "BEFORE=%~2"
set "GOWAIT=%~3"
if "%AFTER%"=="" set "AFTER=origin/main"
if not exist "%LB_HOME%" mkdir "%LB_HOME%"
set "ST=%LB_HOME%\status.txt"
echo look bench start %date% %time% after=%AFTER% before=%BEFORE% > "%ST%"
set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"

if /i not "%GOWAIT%"=="go" goto gook
echo waiting for %VT%\look_bench\go.txt >> "%ST%"
:gowait
if exist "%VT%\look_bench\go.txt" goto gook
timeout /t 60 /nobreak > nul
goto gowait
:gook

rem ---- the bench tool (its own checkout, never the one under test)
set "TOOL=%LB_HOME%\tool"
if not exist "%TOOL%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%TOOL%" > "%LB_HOME%\git_tool.txt" 2>&1
git -C "%TOOL%" fetch origin >> "%LB_HOME%\git_tool.txt" 2>&1
git -C "%TOOL%" checkout -f --detach %LB_TOOL_REF% >> "%LB_HOME%\git_tool.txt" 2>&1
if not exist "%TOOL%\godot\bench\look_bench.gd" (
  echo FAILED: no bench script at %LB_TOOL_REF% >> "%ST%"
  echo FAILED: no bench script at %LB_TOOL_REF%
  goto finish
)
if "%BEFORE%"=="" set /p BEFORE=<"%TOOL%\docs\shots\look_bench\BASELINE.txt"
set "TMO=%TOOL%\tools\pc\tmo.bat"

rem ---- the game checkout under test
set "R=%LB_HOME%\repo"
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%LB_HOME%\git_repo.txt" 2>&1
git -C "%R%" fetch origin >> "%LB_HOME%\git_repo.txt" 2>&1

set "RUN_A="
set "RUN_B="
call :bench "%AFTER%" "%LB_RUN_NAME%" "%LB_PRE_RUN%"
if errorlevel 1 goto finish
set "RUN_A=%RUNDIR%"
set "NAME_A=%RUNNAME%"
if /i "%BEFORE%"=="none" goto sheets
call :bench "%BEFORE%" "" ""
if errorlevel 1 goto finish
set "RUN_B=%RUNDIR%"
set "NAME_B=%RUNNAME%"

:sheets
rem ---- the sheet maker needs Python with Pillow: ComfyUI's portable Python has it
set "PY="
for %%P in ("%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe") do (
  if exist "%%~P" "%%~P" -c "import PIL" > nul 2>&1 && set "PY=%%~P"
)
if "%PY%"=="" (
  py -3 -c "import PIL" > nul 2>&1 && set "PY=py -3"
)
if "%PY%"=="" (
  python -c "import PIL" > nul 2>&1 && set "PY=python"
)
if "%PY%"=="" (
  echo NO PYTHON WITH PILLOW: the stills are in the runs folder, sheets not made >> "%ST%"
  echo No Python with Pillow found: the stills are in %LB_HOME%\runs, the sheets were not made.
  goto finish
)
if "%RUN_B%"=="" (
  set "S=%LB_HOME%\sheets\%NAME_A%"
  set "SARGS=--after "%RUN_A%" --out "!S!""
) else (
  set "S=%LB_HOME%\sheets\%NAME_B%_vs_%NAME_A%"
  set "SARGS=--after "%RUN_A%" --before "%RUN_B%" --out "!S!" --label-after %NAME_A% --label-before %NAME_B%"
)
if not exist "%S%" mkdir "%S%"
%PY% "%TOOL%\tools\pc\jobs\look_bench_sheets.py" %SARGS% > "%S%\sheets_log.txt" 2>&1
echo sheets exit %ERRORLEVEL% %date% %time% %S% >> "%ST%"
if exist "%S%\summary.txt" type "%S%\summary.txt"
if not "%LB_QUIET%"=="1" start "" explorer "%S%"

:finish
echo look bench done %date% %time% >> "%ST%"
echo done > "%LB_HOME%\done.txt"
endlocal
exit /b 0

rem ---------------------------------------------------------------- one bench run: :bench REF [RUNNAME] [PRE_RUN]
:bench
set "REF=%~1"
set "RUNNAME=%~2"
set "PRE=%~3"
git -C "%R%" checkout -f --detach %REF% >> "%LB_HOME%\git_repo.txt" 2>&1
if errorlevel 1 (
  echo FAILED: cannot check out %REF% >> "%ST%"
  echo FAILED: cannot check out %REF%
  exit /b 1
)
for /f %%H in ('git -C "%R%" rev-parse --short^=8 HEAD') do set "SHA=%%H"
if "%RUNNAME%"=="" set "RUNNAME=%SHA%"
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
copy /y "%TOOL%\godot\bench\look_moments.json" "%R%\godot\bench\look_moments.json" > nul
if not "%PRE%"=="" call "%PRE%" "%R%" > "%RUNDIR%\pre_run.txt" 2>&1
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%RUNDIR%\import.txt" 2>&1
echo imported %REF% %SHA% %date% %time% >> "%ST%"
rem one GPU job at a time: wait until the graphics card is idle (under 15 percent), up to 60 minutes
set /a GW=0
:gpuwait
set U=0
for /f %%U in ('nvidia-smi --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits 2^>nul') do set U=%%U
if %U% LSS 15 goto gpufree
set /a GW+=1
if %GW% GEQ 60 goto gpufree
timeout /t 60 /nobreak > nul
goto gpuwait
:gpufree
echo gpu free after %GW% min, bench %REF% %date% %time% >> "%ST%"
call "%TMO%" 3600 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%RUNDIR%" --commit %SHA% > "%RUNDIR%\bench_log.txt" 2>&1
set "BX=%ERRORLEVEL%"
echo bench exit %BX% %REF% %date% %time% >> "%ST%"
rem put the checkout back as the commit has it (the bench files copied in are not part of it)
git -C "%R%" checkout -f --detach %SHA% > nul 2>&1
findstr /c:"LOOK_BENCH placeholder hull" "%RUNDIR%\bench_log.txt" > nul
if not errorlevel 1 (
  echo placeholder hull: STOPPED, %REF% draws a block instead of a ship. Copy the built hulls in, see %RUNDIR%\PLACEHOLDER.txt >> "%ST%"
  echo placeholder hull
  echo STOPPED: %REF% would draw a block instead of a ship. See %RUNDIR%\PLACEHOLDER.txt
  exit /b 1
)
findstr /c:"LOOK_BENCH_DONE" "%RUNDIR%\bench_log.txt" > nul
if errorlevel 1 (
  echo FAILED: the bench did not finish for %REF%, see %RUNDIR%\bench_log.txt >> "%ST%"
  echo FAILED: the bench did not finish for %REF%
  exit /b 1
)
echo %SHA% > "%RUNDIR%\DONE.txt"
exit /b 0
