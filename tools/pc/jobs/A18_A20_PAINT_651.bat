@echo off
title A18, A19 and A20 painted through the recipe, stages 4 to 7 (issue 651) - GPU job
rem Issue 651: the Hullbreaker paint stack on the three class ships (bake "stack"), A20 broadened with open hangar mouths;
rem copied from tools/pc/jobs/A18_A20_RUN_633.bat and PAINT_RUN_601.bat. Clones its own folder opus651\repo (shallow) and
rem checks out branch work/issue-651-opus. For each ship: stages 4 to 7 (stages 1 to 3 outputs are already in recipe\<ship>
rem from the 633 run; stage 4 again because A20's sheet changed and every ship needs the new parts kit), with stage 5's surface
rem check; the install into the clone's own godot folder (C13s_23, C14s_23, C16s_23; what an install replaces is copied aside
rem first); the GPU readback, the authored interiors check and the death seam check on each installed glb; the painted sheet
rem pictures beside the concept (paint_sheet.py on the GPU, paint_compare.py with the game shots). At the end the in-game shots
rem at camera 170 and 60. Each ship runs in its own cmd /c; a failed stage skips that ship's later stages and checks.
rem Every step logs to opus651out\; result.txt lists each exit code. Writes only under opus651\, opus651out\ and recipe\<ship>\.
rem Never deletes anything.
if "%1"=="ship" goto ship
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\opus651\repo
set O=%V%\opus651out
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git clone -q --depth 1 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin work/issue-651-opus >> "%RES%" 2>&1
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
for %%S in (A18:C13s_23 A19:C14s_23 A20:C16s_23) do call :compare %%S
echo done %DATE% %TIME% >> "%RES%"
exit /b 0

:compare
rem the painted pictures beside the concept and the game's own shots (after the shots, so paint_compare can lay them in)
for /f "tokens=1,2 delims=:" %%a in ("%1") do (
  "%BPY%" "%C%\tools\blender\build_sheets\paint_compare.py" "%O%\%%a\paint" "%C%\contrib\muse\design\class_family_corsair_2026_11\corsair_%%a_beauty.jpg" "%O%\shots" %%b "%O%\%%a\pictures" name=%%a > "%O%\log_corsair_%%a_compare.txt" 2>&1
)
echo %1 compare exit %ERRORLEVEL% >> "%RES%"
exit /b 0

:ship
rem one ship, in its own cmd (called above as: this file ship SHIP CELL CODE); C, O, RES, GD, B, INSTALL_TO and RECIPE_NOPAUSE
rem come from the caller
set SHIP=%2
set CELLX=%3
set CODE=%4
set JOBX=%V%\recipe\%2
set CAMJ=
set FAILED=
if not exist "%O%\%CELLX%" mkdir "%O%\%CELLX%"
for %%S in (4_parts_kit 5_paint_bake 6_lod 7_export) do call :stage %%S
if defined FAILED (
  echo %SHIP% checks SKIPPED: stage %FAILED% failed, so the installed glb is not this run's >> "%RES%"
  exit /b 1
)
findstr /c:"surface check" "%JOBX%\log_surface.txt" >> "%RES%" 2>&1
"%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- %CODE% > "%O%\log_%SHIP%_readback_gpu.txt" 2>&1
echo %SHIP% gpu readback exit %ERRORLEVEL% >> "%RES%"
"%GD%" --headless --path "%C%\godot" --script res://fx/test/authored_interiors_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_%SHIP%_interiors.txt" 2>&1
echo %SHIP% authored interiors exit %ERRORLEVEL% >> "%RES%"
"%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_%SHIP%_death_seam.txt" 2>&1
echo %SHIP% death seam exit %ERRORLEVEL% >> "%RES%"
"%B%" -b "%JOBX%\%CELLX%.blend" -P "%C%\tools\blender\build_sheets\paint_sheet.py" -- "%O%\%CELLX%\paint" %SHIP% "%C%\contrib\muse\design\class_family_corsair_2026_11\%SHIP%_beauty.jpg" lift=1.25 samples=64 scale=1.0 gpu=1 > "%O%\log_%SHIP%_paint_sheet.txt" 2>&1
echo %SHIP% paint sheet exit %ERRORLEVEL% >> "%RES%"
for %%F in (density.json %CELLX%.json licences.json lights.json log_surface.txt) do copy /y "%JOBX%\%%F" "%O%\%CELLX%\" > nul
if not exist "%O%\%CELLX%\surface" mkdir "%O%\%CELLX%\surface"
copy /y "%JOBX%\surface\*.*" "%O%\%CELLX%\surface\" > nul
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
