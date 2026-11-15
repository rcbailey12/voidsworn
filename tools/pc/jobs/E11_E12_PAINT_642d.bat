@echo off
title E11 and E12 painted through the recipe, stages 4 to 7 (issue 642, round 3) - GPU job
rem Issue 642: the Eclipse paint stack on both Eclipse sheet ships (bake "stack": tools\blender\kits\eclipse\stack.py), from branch
rem codex/issue-642 in its own clone codex642d\repo (shallow; fetched and checked out at the branch head). For each ship, in its own
rem cmd so nothing one ship's stages set reaches the other (the 618 trap: stage 3 kept the first ship's CAMJ): stages 4 to 7
rem (stages 1 to 3 again first only when the ship's shape reference from the 618 run is missing), with stage 5's surface check;
rem the install into the clone's own godot folder (D22_23 and D21_23; what an install replaces is copied aside first); then the
rem GPU readback, the authored interiors check and the death seam check on the installed glb; the in-game shots (battle, close,
rem cams: camera 170 and 60); the painted pictures beside the concept at the Eclipse battle lift 2.2 (paint_sheet.py on the GPU,
rem paint_compare.py). Each stage's exit code is kept: when a stage fails the later stages and that ship's checks and pictures
rem are skipped (they would read the old hull) and result.txt says so. Every step logs to codex642out_d\<cell>\log_<step>.txt.
rem Writes only under codex642d\, codex642out_d\ and recipe\<ship>\. Never deletes anything.
rem Round 3: aligned recessed panels, readable corona rims, green core, hull trim material exemption only.
if "%1"=="ship" goto ship
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\codex642d\repo
set O=%V%\codex642out_d
if not exist "%V%\codex642d" mkdir "%V%\codex642d"
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git -c core.autocrlf=false clone -q --depth 1 --branch codex/issue-642 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
if errorlevel 1 exit /b 1
git -C "%C%" fetch -q --depth 1 origin codex/issue-642 >> "%RES%" 2>&1
if errorlevel 1 exit /b 1
git -C "%C%" checkout -q --detach FETCH_HEAD >> "%RES%" 2>&1
if errorlevel 1 exit /b 1
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set RECIPE_NOPAUSE=1
set INSTALL_TO=%C%\godot
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set BPY=%V%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe
cd /d "%C%"
"%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
if errorlevel 1 exit /b 1
findstr /b /c:"SCRIPT ERROR:" /c:"ERROR:" "%O%\log_import.txt" > nul
if not errorlevel 1 exit /b 1
rem each ship in a fresh cmd: the variables its stages set end with it
cmd /c ""%~f0" ship deathless_E11 E11 D22_23"
if errorlevel 1 exit /b 1
cmd /c ""%~f0" ship deathless_E12 E12 D21_23"
if errorlevel 1 exit /b 1
rem The binding scene gate: warm once, keep the second run. Both ships are installed in the isolated clone.
for %%N in (1 2) do call :gate %%N
if defined GATE_FAILED exit /b 1
"%BPY%" -c "import json,statistics,math,sys; m=json.load(open(sys.argv[1]))['modes']; a=m['base']; b=m['res_2160']; assert len(a)==3 and len(b)==3; f=statistics.median(r['frame_median'] for r in a); g=statistics.median(r['gpu_median'] for r in b); assert all(math.isfinite(x) and x>0 for x in (f,g)); print('Scene gate: 1080 frame',f,'ms, 4K GPU',g,'ms, limit 12.5 ms'); sys.exit(0 if max(f,g)<=12.5 else 1)" "%O%\scene_gate_2\scene_gate.json" > "%O%\log_gate_result.txt" 2>&1
if errorlevel 1 exit /b 1
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
if not "%EL%"=="0" exit /b 1
findstr /b /c:"SCRIPT ERROR:" /c:"ERROR:" "%OS_%\log_readback_gpu.txt" > nul
if not errorlevel 1 exit /b 1
"%GD%" --headless --path "%C%\godot" --script res://fx/test/authored_interiors_check.gd -- "%C%\godot\assets\ships\%CODEX%\%CODEX%.glb" > "%OS_%\log_interiors.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% authored interiors exit %EL% >> "%RES%"
if not "%EL%"=="0" exit /b 1
findstr /b /c:"SCRIPT ERROR:" /c:"ERROR:" "%OS_%\log_interiors.txt" > nul
if not errorlevel 1 exit /b 1
"%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\%CODEX%\%CODEX%.glb" > "%OS_%\log_death_seam.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% death seam exit %EL% >> "%RES%"
if not "%EL%"=="0" exit /b 1
findstr /b /c:"SCRIPT ERROR:" /c:"ERROR:" "%OS_%\log_death_seam.txt" > nul
if not errorlevel 1 exit /b 1
"%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%OS_%\shots" --facs deathless --sets battle,close,cams --codes %CODEX% > "%OS_%\log_shots.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% shots exit %EL% >> "%RES%"
if not "%EL%"=="0" exit /b 1
findstr /b /c:"SCRIPT ERROR:" /c:"ERROR:" "%OS_%\log_shots.txt" > nul
if not errorlevel 1 exit /b 1
"%B%" -b "%JOBX%\%CELLX%.blend" --python-exit-code 1 -P "%C%\tools\blender\build_sheets\paint_sheet.py" -- "%OS_%\paint" %SHIP% "%C%\contrib\muse\design\concept_round8c_2026_11\%SHIP%_beauty.jpg" lift=2.2 samples=64 scale=1.0 gpu=1 sky_spec=0 cam170=1 > "%OS_%\log_paint_sheet.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% paint sheet exit %EL% >> "%RES%"
if not "%EL%"=="0" exit /b 1
"%BPY%" "%C%\tools\blender\build_sheets\paint_compare.py" "%OS_%\paint" "%C%\contrib\muse\design\concept_round8c_2026_11\%SHIP%_beauty.jpg" "%OS_%\shots" %CODEX% "%OS_%\pictures" name=%CELLX% stack=Eclipse issue=642 > "%OS_%\log_compare.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% compare exit %EL% >> "%RES%"
if not "%EL%"=="0" exit /b 1
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
rem A zero-exit Godot error must fail this ship too.
if "%1"=="6_lod" call :godot_log "%JOBX%\log_godot.txt"
if "%1"=="7_export" call :godot_log "%JOBX%\log_install_cache.txt"
if "%1"=="7_export" call :godot_log "%JOBX%\log_install_readback.txt"
exit /b 0

:gate
if defined GATE_FAILED exit /b 1
call "%C%\tools\pc\tmo.bat" 2400 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\scene_gate_%1" --modes base,res_1440,res_2160 > "%O%\log_scene_gate_%1.txt" 2>&1
set EL=%ERRORLEVEL%
echo scene gate %1 exit %EL% >> "%RES%"
if not "%EL%"=="0" set GATE_FAILED=1
findstr /l /c:"[scene_gate] DONE" "%O%\log_scene_gate_%1.txt" > nul
if errorlevel 1 set GATE_FAILED=1
findstr /b /c:"SCRIPT ERROR:" /c:"ERROR:" "%O%\log_scene_gate_%1.txt" > nul
if not errorlevel 1 set GATE_FAILED=1
exit /b 0

:godot_log
if not exist "%~1" (set FAILED=missing_Godot_log & exit /b 1)
findstr /b /c:"SCRIPT ERROR:" /c:"ERROR:" "%~1" > nul
if not errorlevel 1 set FAILED=Godot_error
exit /b 0
