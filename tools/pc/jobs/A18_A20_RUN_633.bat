@echo off
title A18, A19 and A20 (the Hullbreaker Sniffer, Mauler and Den) through the recipe, stages 1 to 7 (issue 633) - GPU job
rem Issue 633: the three Hullbreaker class ships through the ship recipe, unpainted (bake none), the route E11 and E12 (issue
rem 618, PR 620) and C10 and C11 (issue 623) took; copied from tools/pc/jobs/C10_C11_RUN_623.bat on branch opus/issue-623.
rem Clones its own folder opus633\repo (shallow) and checks out branch opus/issue-633. For each ship: stages 1 to 7 (job folder
rem recipe\corsair_A18, corsair_A19 or corsair_A20), the install into the clone's own godot folder (folders C13s_23, the
rem Hullbreaker Frigate, C14s_23, the Destroyer, and C16s_23, the Carrier, in godot/render/hull_table.gd AI_HULLS, the ones the
rem game draws; what an install replaces is copied aside first, nothing is deleted), then the GPU readback, the authored
rem interiors check and the death seam check on each installed glb, and at the end the in-game shots at camera 170 and 60.
rem Each ship runs in its own cmd /c, so nothing set by one ship's stages (CAMJ and the rest) carries to the next; each stage's
rem exit code is kept, so when a stage fails the later stages and that ship's checks are skipped (a failed ship's checks would
rem read the old hull) and the result says so.
rem Every step logs to opus633out\log_<ship>_<step>.txt; result.txt lists each exit code. After stage 3, read each ship's yaw
rem overlay and write shape_ref_yaw into its json, as for A16, A17, E11, E12, C10 and C11.
if "%1"=="ship" goto ship
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\opus633\repo
set O=%V%\opus633out
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git clone -q --depth 1 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin opus/issue-633 >> "%RES%" 2>&1
git -C "%C%" checkout -q FETCH_HEAD >> "%RES%" 2>&1
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set RECIPE_NOPAUSE=1
set INSTALL_TO=%C%\godot
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
cd /d "%C%"
"%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
rem each ship in a fresh cmd: the variables its stages set end with it
cmd /c ""%~f0" ship corsair_A18 C13s_23"
cmd /c ""%~f0" ship corsair_A19 C14s_23"
cmd /c ""%~f0" ship corsair_A20 C16s_23"
"%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs corsair --sets battle,close --codes C13s_23,C14s_23,C16s_23 > "%O%\log_shots.txt" 2>&1
echo shots exit %ERRORLEVEL% >> "%RES%"
echo done %DATE% %TIME% >> "%RES%"
exit /b 0

:ship
rem one ship, in its own cmd (called above as: this file ship SHIP CODE); C, O, RES, GD, INSTALL_TO and RECIPE_NOPAUSE come
rem from the caller
set SHIP=%2
set CODE=%3
set CAMJ=
set FAILED=
for %%S in (1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export) do call :stage %%S
if defined FAILED (
  echo %SHIP% checks SKIPPED: stage %FAILED% failed, so the installed glb is not this run's >> "%RES%"
  exit /b 1
)
"%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- %CODE% > "%O%\log_%SHIP%_readback_gpu.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% gpu readback exit %EL% >> "%RES%"
"%GD%" --headless --path "%C%\godot" --script res://fx/test/authored_interiors_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_%SHIP%_interiors.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% authored interiors exit %EL% >> "%RES%"
"%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_%SHIP%_death_seam.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% death seam exit %EL% >> "%RES%"
exit /b 0

:stage
if defined FAILED (
  echo %SHIP% %1 SKIPPED: stage %FAILED% failed >> "%RES%"
  exit /b 0
)
echo %SHIP% %1 start %TIME% >> "%RES%"
call "%C%\tools\recipe\%1.bat" > "%O%\log_%SHIP%_%1.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% %1 exit %EL% at %TIME% >> "%RES%"
if not "%EL%"=="0" set FAILED=%1
exit /b 0
