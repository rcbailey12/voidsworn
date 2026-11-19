@echo off
rem Issue 1235 (Opus helper): ships look damaged from the first hit. Look bench, before (main) and after (opus/issue-1235):
rem one torpedo on a fresh Sunward V16_37, Glasswright I15_11 and Chorus B21_11 cruiser, and every section at stage 4,
rem at camera 170 and camera 26. Rows: godot/bench/look_moments_first_hit.json (read from the branch for both runs).
rem Its own clone in Downloads\voidsworn_test\opus1235; hulls copied in from the audit2 checkout (copy only).
rem Each capture runs in a throwaway profile (APPDATA and LOCALAPPDATA pointed at its own folder, R334, issue 1228).
rem Each Godot run goes through tmo.bat, so the GPU slots are respected. Nothing on the PC is deleted.
rem Output: Downloads\voidsworn_test\opus1235\shots\before|after\moments\*.png and status.txt.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus1235"
set "R=%H%\repo"
set "BR=opus/issue-1235"
if "%LB_SHIPS%"=="" set "LB_SHIPS=%VT%\audit2\repo\godot"
set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "TMO=%VT%\tools\pc\tmo.bat"
if not exist "%TMO%" set "TMO=%R%\tools\pc\tmo.bat"
if not exist "%H%" mkdir "%H%"
set "ST=%H%\status.txt"
echo shots1235 start %date% %time% > "%ST%"
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%H%\git.txt" 2>&1
git -C "%R%" fetch origin main %BR% >> "%H%\git.txt" 2>&1
git -C "%R%" show origin/%BR%:godot/bench/look_moments_first_hit.json > "%H%\rows.json"
if errorlevel 1 (
  echo FAILED: no rows file on %BR% >> "%ST%"
  goto done
)
call :one after origin/%BR%
call :one before origin/main
echo shots1235 done %date% %time% >> "%ST%"
:done
type "%ST%"
exit /b 0

:one
set "NAME=%~1"
set "O=%H%\shots\%NAME%"
if not exist "%O%" mkdir "%O%"
git -C "%R%" checkout -f --detach %~2 >> "%H%\git.txt" 2>&1
if errorlevel 1 (
  echo FAILED: cannot check out %~2 >> "%ST%"
  exit /b 1
)
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt"
if exist "%LB_SHIPS%\gen" robocopy "%LB_SHIPS%\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if exist "%LB_SHIPS%\assets\ships" robocopy "%LB_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if not exist "%R%\godot\.godot" if exist "%LB_SHIPS%\.godot" robocopy "%LB_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
copy /y "%H%\rows.json" "%R%\godot\bench\look_moments_first_hit.json" > nul
set "PICTURE_SOURCE_REPO=%R%"
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
set "P=%H%\profile\%NAME%"
if not exist "%P%" mkdir "%P%"
set "OLDAPP=%APPDATA%"
set "OLDLOC=%LOCALAPPDATA%"
set "APPDATA=%P%"
set "LOCALAPPDATA=%P%"
set "VS_CAPTURE_PROFILE=%P%"
call "%TMO%" 1800 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%O%" --part moments --moments res://bench/look_moments_first_hit.json > "%O%\log.txt" 2>&1
set "APPDATA=%OLDAPP%"
set "LOCALAPPDATA=%OLDLOC%"
set "VS_CAPTURE_PROFILE="
findstr /c:"LOOK_BENCH_DONE" "%O%\log.txt" >> "%ST%" || echo FAILED: %NAME%, see %O%\log.txt >> "%ST%"
git -C "%R%" checkout -f --detach %~2 > nul 2>&1
exit /b 0
