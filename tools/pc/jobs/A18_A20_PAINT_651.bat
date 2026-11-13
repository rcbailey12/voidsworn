@echo off
title A18, A19 and A20 painted through the recipe, stages 3 to 7 (issue 651) - GPU job
rem Issue 651: the three Hullbreaker class ships (the Sniffer, the Mauler and the Den) painted by the accepted Hullbreaker paint
rem stack (bake "stack", R235), A20 with its issue 651 massing change (the broad slab, the two hangar mouths in the bow face).
rem Copied from tools/pc/jobs/A18_A20_RUN_633.bat (one cmd per ship, every stage's exit code kept, a ship's checks skipped
rem after a failed stage) and tools/pc/jobs/PAINT_RUN_601.bat (surface check, painted pictures beside the concept).
rem Clones its own folder opus651\repo (shallow) and checks out branch opus/issue-651. For each ship: stages 3 to 7 in the job
rem folder recipe\corsair_A18, corsair_A19 or corsair_A20 (stages 1 and 2 are already there from the 633 run; stage 3 again
rem because A20's sheet changed), with stage 5's surface check; the install into the clone's own godot folder (C13s_23, C14s_23
rem and C16s_23, what an install replaces is copied aside first); the GPU readback, the authored interiors check and the death
rem seam check on each installed glb; the painted pictures (paint_sheet.py on the GPU, then paint_compare.py with the game
rem shots). At the end the in-game shots of all three at camera 170 and 60 (battle, close, cams) and the compares.
rem Every step logs to opus651out\log_<ship>_<step>.txt; result.txt lists each exit code. Writes only under opus651\,
rem opus651out\ and recipe\<ship>\. Never deletes anything.
if "%1"=="ship" goto ship
if "%1"=="pics" goto pics
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\opus651\repo
set O=%V%\opus651out
if not exist "%V%\opus651" mkdir "%V%\opus651"
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git clone -q --depth 1 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin opus/issue-651 >> "%RES%" 2>&1
git -C "%C%" checkout -q -f FETCH_HEAD >> "%RES%" 2>&1
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set RECIPE_NOPAUSE=1
set INSTALL_TO=%C%\godot
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set BPY=%V%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe
cd /d "%C%"
"%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
rem each ship in a fresh cmd: the variables its stages set end with it
cmd /c ""%~f0" ship corsair_A18 A18 C13s_23"
cmd /c ""%~f0" ship corsair_A19 A19 C14s_23"
cmd /c ""%~f0" ship corsair_A20 A20 C16s_23"
"%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs corsair --sets battle,close,cams --codes C13s_23,C14s_23,C16s_23 > "%O%\log_shots.txt" 2>&1
echo shots exit %ERRORLEVEL% >> "%RES%"
cmd /c ""%~f0" pics corsair_A18 A18 C13s_23"
cmd /c ""%~f0" pics corsair_A19 A19 C14s_23"
cmd /c ""%~f0" pics corsair_A20 A20 C16s_23"
echo done %DATE% %TIME% >> "%RES%"
exit /b 0

:ship
rem one ship, in its own cmd (called above as: this file ship SHIP CELL CODE); C, O, RES, GD, B, BPY, INSTALL_TO and
rem RECIPE_NOPAUSE come from the caller
set SHIP=%2
set CELLX=%3
set CODE=%4
set JOBX=%V%\recipe\%2
set CAMJ=
set FAILED=
for %%S in (3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export) do call :stage %%S
if not exist "%O%\%CELLX%" mkdir "%O%\%CELLX%"
for %%F in (density.json %CELLX%.json licences.json lights.json log_surface.txt) do if exist "%JOBX%\%%F" copy /y "%JOBX%\%%F" "%O%\%CELLX%\" > nul
if not exist "%O%\%CELLX%\surface" mkdir "%O%\%CELLX%\surface"
if exist "%JOBX%\surface" copy /y "%JOBX%\surface\*.*" "%O%\%CELLX%\surface\" > nul
if exist "%JOBX%\log_surface.txt" findstr /c:"surface check" "%JOBX%\log_surface.txt" >> "%RES%" 2>&1
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
"%B%" -b "%JOBX%\%CELLX%.blend" -P "%C%\tools\blender\build_sheets\paint_sheet.py" -- "%O%\%CELLX%\paint" %SHIP% "%C%\contrib\muse\design\class_family_corsair_2026_11\%SHIP%_beauty.jpg" lift=1.25 samples=64 scale=1.0 gpu=1 > "%O%\log_%SHIP%_paint_sheet.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% paint sheet exit %EL% >> "%RES%"
exit /b 0

:pics
rem the compares beside the concept, once the game shots exist (called above as: this file pics SHIP CELL CODE)
set SHIP=%2
set CELLX=%3
set CODE=%4
if not exist "%O%\%CELLX%\paint" (
  echo %SHIP% compare SKIPPED: no paint pictures >> "%RES%"
  exit /b 0
)
"%BPY%" "%C%\tools\blender\build_sheets\paint_compare.py" "%O%\%CELLX%\paint" "%C%\contrib\muse\design\class_family_corsair_2026_11\%SHIP%_beauty.jpg" "%O%\shots" %CODE% "%O%\%CELLX%\pictures" name=%CELLX% > "%O%\log_%SHIP%_compare.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% compare exit %EL% >> "%RES%"
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
