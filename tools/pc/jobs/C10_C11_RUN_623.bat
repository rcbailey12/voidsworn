@echo off
title C10 and C11 (Chorus flagship and bladeback) through the recipe, stages 1 to 7 (issue 623) - GPU job
rem Issue 623: the first two Chorus ships through the ship recipe, unpainted (bake none), the route E11 and E12 took (issue 618,
rem PR 620). Clones its own folder opus623\repo (shallow) and checks out branch opus/issue-623. For each ship: stages 1 to 7 (job
rem folder recipe\chorus_C10 or recipe\chorus_C11), the install into the clone's own godot folder (folder B16_23, the Chorus
rem Bio-titan, and B21_11, the Chorus Cruiser, that the game draws; what an install replaces is copied aside first, nothing is
rem deleted), then the GPU readback, the authored interiors check and the death seam check on each installed glb, and at the end
rem the in-game shots at camera 170 and 60 for both.
rem Two fixes from the 618 PC run (Nov 13): each ship runs in its own cmd /c, so nothing set by the first ship's stages (CAMJ and
rem the rest) carries to the second; and each stage's exit code is kept, so when a stage fails the later stages and that ship's
rem checks are skipped (a failed ship's checks would read the old hull) and the result says so.
rem Every step logs to opus623out\log_<ship>_<step>.txt; result.txt lists each exit code. After stage 3, read each ship's yaw
rem overlay and write shape_ref_yaw into its json, as for A16, A17, E11 and E12.
if "%1"=="ship" goto ship
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\opus623\repo
set O=%V%\opus623out
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git clone -q --depth 1 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin opus/issue-623 >> "%RES%" 2>&1
git -C "%C%" checkout -q FETCH_HEAD >> "%RES%" 2>&1
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set RECIPE_NOPAUSE=1
set INSTALL_TO=%C%\godot
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
cd /d "%C%"
"%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
rem each ship in a fresh cmd: the variables its stages set end with it
cmd /c ""%~f0" ship chorus_C10 B16_23"
cmd /c ""%~f0" ship chorus_C11 B21_11"
"%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs chorus --sets battle,close --codes B16_23,B21_11 > "%O%\log_shots.txt" 2>&1
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
