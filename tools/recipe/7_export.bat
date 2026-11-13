@echo off
rem Ship recipe, stage 7: the game export, automated (issue 209 round 7; FINDINGS R155, R156; issue 363).
rem From the baked ship (stage 5) and the ship json, with no hand steps, this writes the game's ship folder into
rem Downloads\voidsworn_test\recipe\SHIP\export\CODE\ : CODE.glb (one ship node with a child node per hard point: hp_w per weapon
rem muzzle, hp_eng, hp_bay, hp_breach, hp_core, hp_rcs, hp_board) and the 2048 map set (export7.py), plus manifest_entry.json
rem with the point counts. Then it reads the glb back and checks it (check_export.py): FAIL when a required point is missing
rem (a weapon slot of the ship's data.js weapon list, an engine, a hangar mouth, the core, the braking and boarding origins), or
rem the breach count for the ship's class and faction does not match the one table (tools/blender/kits/shared/hardpoints.py),
rem or a hard point is off the mesh; see docs/ship_pipeline/HARDPOINTS.md. The standing checks (outline per third, inner edges,
rem second camera, paint sides, blink sheet, licences, light sizes) must also pass before anything is written.
rem Last, it proves the check itself can fail (check_export_selftest.py: every broken copy must be refused, each for its reason).
rem It never copies into the game on its own. To install a checked export, set INSTALL_TO to a Godot project folder (the folder
rem that holds project.godot) before running this: the files it replaces are first copied to export\replaced_DATE\, and the old
rem ship's wreck and damage files are moved there too (they belong to the old hull). Nothing is deleted. The install also merges
rem manifest_entry.json into INSTALL_TO\assets\ships\manifest.json, so the point counts are recorded per ship, refreshes the
rem game's ship cache (render\build_assets.gd --ships-only) and reads the ship back as the game draws it (issue 592).
rem Set RECIPE_NOPAUSE=1 to run it from another job without the key press at the end.
call "%~dp0env.bat"
set EX=%JOB%\export\%CODE%
rem issue 592: a ship with no paint stack yet ("bake": "none") is exported and checked as an unbaked test export
set UNB=
if /i "%BAKE%"=="none" set UNB=unbaked=1
if not "%STACK_NOTE%"=="" echo Stage 7: %STACK_NOTE%: an unbaked test export
if not exist "%JOB%\%CELL%.blend" (echo Stage 7 FAILED: no baked ship at %JOB%\%CELL%.blend. Run stage 5 first. & goto bad)
if not exist "%EX%" mkdir "%EX%"
echo RUNNING > "%EX%\export_status.txt"
"%BPY%" "%RC%\standing.py" all --ship "%R209_SHIP%" --job "%JOB%" > "%JOB%\log_standing_all.txt" 2>&1
if errorlevel 1 (type "%JOB%\log_standing_all.txt" & echo Stage 7 FAILED: a standing ship check did not pass. See %JOB%\log_standing_all.txt & goto bad)
type "%JOB%\log_standing_all.txt"
"%B%" -b "%JOB%\%CELL%.blend" -P "%RC%\export7.py" -- "%R209_SHIP%" "%EX%" maps=2048 %UNB% > "%JOB%\log_export.txt" 2>&1
findstr /c:"[export7]" "%JOB%\log_export.txt"
findstr /b /c:"WRITTEN" "%EX%\export_status.txt" > nul
if errorlevel 1 (echo Stage 7 FAILED: the export was not written. See %JOB%\log_export.txt & goto bad)
"%BPY%" "%RC%\check_export.py" "%R209_SHIP%" "%EX%" %UNB% > "%JOB%\log_export_check.txt" 2>&1
set CHK=%errorlevel%
type "%JOB%\log_export_check.txt"
if not "%CHK%"=="0" (echo CHECK FAILED > "%EX%\export_status.txt" & echo Stage 7 FAILED: %EX% is not a game ship folder. Nothing was installed. & goto bad)
"%BPY%" "%RC%\check_export_selftest.py" "%R209_SHIP%" "%EX%" %UNB% > "%JOB%\log_export_selftest.txt" 2>&1
set SELF=%errorlevel%
type "%JOB%\log_export_selftest.txt"
if not "%SELF%"=="0" (echo SELFTEST FAILED > "%EX%\export_status.txt" & echo Stage 7 FAILED: the export check did not refuse a broken export. Nothing was installed. & goto bad)
echo CHECKED >> "%EX%\export_status.txt"
if "%INSTALL_TO%"=="" goto done
if not exist "%INSTALL_TO%\project.godot" (echo Stage 7: INSTALL_TO is not a Godot project folder: %INSTALL_TO%. Nothing was installed. & goto bad)
set SH=%INSTALL_TO%\assets\ships\%CODE%
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set STAMP=%%T
set OLD=%JOB%\export\replaced_%STAMP%
if not exist "%SH%" mkdir "%SH%"
if not exist "%OLD%" mkdir "%OLD%"
if exist "%SH%\%CODE%.glb" copy /y "%SH%\%CODE%*.*" "%OLD%\" > nul
if exist "%SH%\%CODE%_wreck.glb" move /y "%SH%\%CODE%_wreck.glb" "%OLD%\" > nul
if exist "%SH%\%CODE%_damage.glb" move /y "%SH%\%CODE%_damage.glb" "%OLD%\" > nul
copy /y "%EX%\%CODE%.glb" "%SH%\" > nul
copy /y "%EX%\%CODE%*.jpg" "%SH%\" > nul
"%BPY%" "%RC%\manifest_merge.py" "%EX%\manifest_entry.json" "%INSTALL_TO%" "%CODE%"
if errorlevel 1 (echo Stage 7 FAILED: the manifest entry was not merged into %INSTALL_TO%\assets\ships\manifest.json & goto bad)
rem issue 592: copying the glb is not enough, the game draws ships from its asset cache (gen\manifest.json). Refresh the ship
rem cache from the installed folders, then read the ship back the way the game will (ShipView), or the old hull stays on screen.
"%GD%" --headless --path "%INSTALL_TO%" --script res://render/build_assets.gd -- --ships-only > "%JOB%\log_install_cache.txt" 2>&1
findstr /c:"[assets] ships refreshed" "%JOB%\log_install_cache.txt" > nul || (echo Stage 7 FAILED: the game's ship cache was not refreshed. See %JOB%\log_install_cache.txt & goto bad)
"%GD%" --headless --path "%INSTALL_TO%" --script res://render/test/installed_ship_check.gd -- %CODE% > "%JOB%\log_install_readback.txt" 2>&1
findstr /c:"INSTALL READBACK PASS" "%JOB%\log_install_readback.txt" > nul || (type "%JOB%\log_install_readback.txt" & echo Stage 7 FAILED: the game does not draw the new %CODE%. See %JOB%\log_install_readback.txt & goto bad)
type "%JOB%\log_install_readback.txt" | findstr /c:"INSTALL READBACK"
echo Installed into %SH% (what was there before is in %OLD%); the game's ship cache is refreshed
:done
echo Stage 7 done: PASS. The game's ship folder is %EX%
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 0
:bad
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 1
