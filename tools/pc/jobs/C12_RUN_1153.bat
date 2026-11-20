@echo off
title C12 drone-spawn (Chorus frigate B19_11) through the recipe (issue 1153) - GPU job
rem Issue 1153: the Chorus drone-spawn frigate from its build sheet chorus_C12 through the ship recipe. Clones its own folder
rem opus1153\repo (shallow) and checks out branch opus/issue-1153. Runs the stages named on the command line (default: 1 to 4,
rem the job's first step; then 5 to 7 once the Board has looked at the blockout), each with its exit code kept: when a stage fails
rem the later ones are skipped and the result says so. Stages 6 and 7 install into the clone's own godot folder only (B19_11, the
rem chorus|Frigate folder; what an install replaces is copied aside first, nothing is deleted), never into the shared game.
rem Every step logs to opus1153out\log_<step>.txt; result.txt lists each exit code. Usage:
rem   C12_RUN_1153.bat            stages 1 to 4
rem   C12_RUN_1153.bat 5 6 7      stages 5 to 7 (with the checks on the installed glb after stage 7)
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\opus1153\repo
set O=%V%\opus1153out
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% args %* >> "%RES%"
if not exist "%C%\.git" git clone -q --depth 1 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin opus/issue-1153 >> "%RES%" 2>&1
git -C "%C%" checkout -q FETCH_HEAD >> "%RES%" 2>&1
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set RECIPE_NOPAUSE=1
set INSTALL_TO=%C%\godot
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set SHIP=chorus_C12
set CODE=B19_11
set FAILED=
set ST=%*
if "%ST%"=="" set ST=1 2 3 4
cd /d "%C%"
for %%N in (%ST%) do call :num %%N
if defined FAILED goto done
echo %ST% | findstr /c:"7" >nul || goto done
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- %CODE% > "%O%\log_readback_gpu.txt" 2>&1
echo gpu readback exit %ERRORLEVEL% >> "%RES%"
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --script res://fx/test/authored_interiors_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_interiors.txt" 2>&1
echo authored interiors exit %ERRORLEVEL% >> "%RES%"
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_death_seam.txt" 2>&1
echo death seam exit %ERRORLEVEL% >> "%RES%"
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs chorus --sets battle,close --codes %CODE% > "%O%\log_shots.txt" 2>&1
echo shots exit %ERRORLEVEL% >> "%RES%"
:done
echo done %DATE% %TIME% >> "%RES%"
exit /b 0

:num
if "%1"=="1" call :stage 1_concept_in
if "%1"=="2" call :stage 2_shape_ref
if "%1"=="3" call :stage 3_trace_hull
if "%1"=="4" call :stage 4_parts_kit
if "%1"=="5" call :stage 5_paint_bake
if "%1"=="6" call :stage 6_lod
if "%1"=="7" call :stage 7_export
exit /b 0

:stage
if defined FAILED (
  echo %SHIP% %1 SKIPPED: stage %FAILED% failed >> "%RES%"
  exit /b 0
)
echo %SHIP% %1 start %TIME% >> "%RES%"
call "%C%\tools\recipe\%1.bat" > "%O%\log_%1.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% %1 exit %EL% at %TIME% >> "%RES%"
if not "%EL%"=="0" set FAILED=%1
exit /b 0
