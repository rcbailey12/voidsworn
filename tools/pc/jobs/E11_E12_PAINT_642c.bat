@echo off
title E11 and E12 painted through the recipe, stages 4 to 7 (issue 642, run c) - GPU job
rem Issue 642: the Eclipse paint stack on both Eclipse sheet ships (bake "stack": tools\blender\kits\eclipse\stack.py), from branch
rem work/issue-642-opus in its own clone opus642c\repo (shallow; fetched and checked out at the branch head). For each ship, in its own
rem cmd so nothing one ship's stages set reaches the other (the 618 trap: stage 3 kept the first ship's CAMJ): stages 4 to 7
rem (stages 1 to 3 again first only when the ship's shape reference from the 618 run is missing), with stage 5's surface check;
rem the install into the clone's own godot folder (D22_23 and D21_23; what an install replaces is copied aside first); then the
rem GPU readback, the authored interiors check and the death seam check on the installed glb; the in-game shots (battle, close,
rem cams: camera 170 and 60); the painted pictures beside the concept at the Eclipse battle lift 2.2 (paint_sheet.py on the GPU,
rem paint_compare.py). Each stage's exit code is kept: when a stage fails the later stages and that ship's checks and pictures
rem are skipped (they would read the old hull) and result.txt says so. Every step logs to opus642out_c\<cell>\log_<step>.txt.
rem Writes only under opus642c\, opus642out_c\ and recipe\<ship>\. Never deletes anything.
rem Run c (Nov 13 2026): the runs 642 and 642b crashed in stage 5 on Blender 4.5 (EXCEPTION_ACCESS_VIOLATION in the
rem depsgraph): the Eclipse stack wrote the light inputs through a colour attribute handle taken before it added ps_kind.
rem stack.py now adds both attributes first and writes them after; the same stages 4 to 7 passed on Blender 4.5.14 locally.
if "%1"=="ship" goto ship
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\opus642c\repo
set O=%V%\opus642out_c
if not exist "%V%\opus642c" mkdir "%V%\opus642c"
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git clone -q --depth 1 --branch work/issue-642-opus https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin work/issue-642-opus >> "%RES%" 2>&1
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
cmd /c ""%~f0" ship deathless_E11 E11 D22_23"
cmd /c ""%~f0" ship deathless_E12 E12 D21_23"
echo done %DATE% %TIME% >> "%RES%"
exit /b 0

:ship
rem one ship, in its own cmd (called above as: this file ship SHIP CELL CODE); V, C, O, RES, GD, B, BPY, INSTALL_TO and
rem RECIPE_NOPAUSE come from the caller
set SHIP=%2
set CELLX=%3
set CODEX=%4
set JOBX=%V%\recipe\%2
set OS_=%O%\%3
set CAMJ=
set FAILED=
if not exist "%OS_%" mkdir "%OS_%"
echo === %SHIP% %TIME% >> "%RES%"
set STAGES=4_parts_kit 5_paint_bake 6_lod 7_export
if not exist "%V%\bakeoff\%SHIP%_trellis.glb" set STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export
if not exist "%JOBX%\concept.png" set STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export
echo %SHIP% stages %STAGES% >> "%RES%"
for %%S in (%STAGES%) do call :stage %%S
findstr /c:"surface check" "%JOBX%\log_surface.txt" >> "%RES%" 2>&1
for %%F in (density.json %CELLX%.json licences.json log_surface.txt log_bake.txt audit.json) do if exist "%JOBX%\%%F" copy /y "%JOBX%\%%F" "%OS_%\" > nul
if not exist "%OS_%\surface" mkdir "%OS_%\surface"
if exist "%JOBX%\surface" copy /y "%JOBX%\surface\*.*" "%OS_%\surface\" > nul
if exist "%JOBX%\export\%CODEX%\%CODEX%_export.json" copy /y "%JOBX%\export\%CODEX%\%CODEX%_export.json" "%OS_%\" > nul
if defined FAILED (
  echo %SHIP% checks, shots and pictures SKIPPED: stage %FAILED% failed, so the installed glb is not this run's >> "%RES%"
  exit /b 1
)
"%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- %CODEX% > "%OS_%\log_readback_gpu.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% gpu readback exit %EL% >> "%RES%"
"%GD%" --headless --path "%C%\godot" --script res://fx/test/authored_interiors_check.gd -- "%C%\godot\assets\ships\%CODEX%\%CODEX%.glb" > "%OS_%\log_interiors.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% authored interiors exit %EL% >> "%RES%"
"%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\%CODEX%\%CODEX%.glb" > "%OS_%\log_death_seam.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% death seam exit %EL% >> "%RES%"
"%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%OS_%\shots" --facs deathless --sets battle,close,cams --codes %CODEX% > "%OS_%\log_shots.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% shots exit %EL% >> "%RES%"
"%B%" -b "%JOBX%\%CELLX%.blend" -P "%C%\tools\blender\build_sheets\paint_sheet.py" -- "%OS_%\paint" %SHIP% "%C%\contrib\muse\design\concept_round8c_2026_11\%SHIP%_beauty.jpg" lift=2.2 samples=64 scale=1.0 gpu=1 sky_spec=0 cam170=1 > "%OS_%\log_paint_sheet.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% paint sheet exit %EL% >> "%RES%"
"%BPY%" "%C%\tools\blender\build_sheets\paint_compare.py" "%OS_%\paint" "%C%\contrib\muse\design\concept_round8c_2026_11\%SHIP%_beauty.jpg" "%OS_%\shots" %CODEX% "%OS_%\pictures" name=%CELLX% stack=Eclipse issue=642 > "%OS_%\log_compare.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% compare exit %EL% >> "%RES%"
exit /b 0

:stage
if defined FAILED (
  echo %SHIP% %1 SKIPPED: stage %FAILED% failed >> "%RES%"
  exit /b 0
)
echo %SHIP% %1 start %TIME% >> "%RES%"
call "%C%\tools\recipe\%1.bat" > "%OS_%\log_%1.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% %1 exit %EL% at %TIME% >> "%RES%"
if not "%EL%"=="0" set FAILED=%1
exit /b 0
