@echo off
title E11 and E12 (Eclipse flagship and ring cruiser) through the recipe, stages 1 to 7 (issue 618) - GPU job
rem Issue 618: the first two Eclipse ships through the ship recipe, unpainted (bake none), the route A16 and A17 proved
rem (issues 592 and 532; PRs 596, 606, 611). Uses the existing opus592\repo clone (no new clone, the PC folder stays lean) and
rem checks out branch opus/issue-618. For each ship: stages 1 to 7 (job folder recipe\deathless_E11 or recipe\deathless_E12), the
rem install into the clone's own godot folder (folder D22_23, the Eclipse Tomb-ark, and D21_23, the Eclipse Cruiser, that the
rem game draws; what an install replaces is copied aside first, nothing is deleted), then the in-game shots at camera 170 and 60
rem for both, the GPU readback, the authored interiors check and the death seam check on each installed glb.
rem Every step logs to opus618out\log_<ship>_<step>.txt; result.txt lists each exit code. After stage 3, read each ship's yaw
rem overlay and write shape_ref_yaw into its json, as for A16 and A17.
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\opus592\repo
set O=%V%\opus618out
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git clone -q --depth 1 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin opus/issue-618 >> "%RES%" 2>&1
git -C "%C%" checkout -q FETCH_HEAD >> "%RES%" 2>&1
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set RECIPE_NOPAUSE=1
set INSTALL_TO=%C%\godot
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
cd /d "%C%"
"%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
call :ship deathless_E11 D22_23
call :ship deathless_E12 D21_23
"%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs deathless --sets battle,close --codes D22_23,D21_23 > "%O%\log_shots.txt" 2>&1
echo shots exit %ERRORLEVEL% >> "%RES%"
echo done %DATE% %TIME% >> "%RES%"
exit /b 0

:ship
set SHIP=%1
set CODE=%2
for %%S in (1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export) do call :stage %%S
"%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- %CODE% > "%O%\log_%SHIP%_readback_gpu.txt" 2>&1
echo %SHIP% gpu readback exit %ERRORLEVEL% >> "%RES%"
"%GD%" --headless --path "%C%\godot" --script res://fx/test/authored_interiors_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_%SHIP%_interiors.txt" 2>&1
echo %SHIP% authored interiors exit %ERRORLEVEL% >> "%RES%"
"%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_%SHIP%_death_seam.txt" 2>&1
echo %SHIP% death seam exit %ERRORLEVEL% >> "%RES%"
exit /b 0

:stage
echo %SHIP% %1 start %TIME% >> "%RES%"
call "%C%\tools\recipe\%1.bat" > "%O%\log_%SHIP%_%1.txt" 2>&1
echo %SHIP% %1 exit %ERRORLEVEL% at %TIME% >> "%RES%"
exit /b 0
