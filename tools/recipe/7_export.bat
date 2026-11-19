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
rem that holds project.godot) before running this. The installer checks a snapshot, locks the project, prepares backups,
rem then installs the checked files and refreshes the ship cache. It checks the installed hashes and reads the ship back
rem as the game draws it. On failure it restores the old files (issues 592, 1101).
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
set "TMO_STEP=recipe 7 check ship records"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_CHECK_CAP% "%BPY%" -u "%RC%\standing.py" all --ship "%R209_SHIP%" --job "%JOB%" > "%JOB%\log_standing_all.txt" 2>&1
if errorlevel 1 (type "%JOB%\log_standing_all.txt" & echo Stage 7 FAILED: a standing ship check did not pass. See %JOB%\log_standing_all.txt & goto bad)
type "%JOB%\log_standing_all.txt"
setlocal
set "PC_GPU_MODE=none"
set "TMO_STEP=recipe 7 game export"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_EXPORT_CAP% "%B%" -b "%JOB%\%CELL%.blend" -P "%RC%\export7.py" -- "%R209_SHIP%" "%EX%" maps=2048 %UNB% > "%JOB%\log_export.txt" 2>&1
if errorlevel 1 (echo Stage 7 FAILED: the game export exited %ERRORLEVEL%. See %JOB%\log_export.txt & goto bad)
endlocal
findstr /c:"[export7]" "%JOB%\log_export.txt"
findstr /b /c:"WRITTEN" "%EX%\export_status.txt" > nul
if errorlevel 1 (echo Stage 7 FAILED: the export was not written. See %JOB%\log_export.txt & goto bad)
if not "%INSTALL_TO%"=="" goto install
set "TMO_STEP=recipe 7 validate export"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_CHECK_CAP% "%BPY%" -u "%RC%\check_export.py" "%R209_SHIP%" "%EX%" %UNB% > "%JOB%\log_export_check.txt" 2>&1
set CHK=%errorlevel%
type "%JOB%\log_export_check.txt"
if not "%CHK%"=="0" (echo CHECK FAILED > "%EX%\export_status.txt" & echo Stage 7 FAILED: %EX% is not a game ship folder. Nothing was installed. & goto bad)
set "TMO_STEP=recipe 7 prove the export check"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_CHECK_CAP% "%BPY%" -u "%RC%\check_export_selftest.py" "%R209_SHIP%" "%EX%" %UNB% > "%JOB%\log_export_selftest.txt" 2>&1
set SELF=%errorlevel%
type "%JOB%\log_export_selftest.txt"
if not "%SELF%"=="0" (echo SELFTEST FAILED > "%EX%\export_status.txt" & echo Stage 7 FAILED: the export check did not refuse a broken export. Nothing was installed. & goto bad)
echo CHECKED >> "%EX%\export_status.txt"
goto done
:install
rem The installer owns rollback. Its Godot commands return to it on timeout so it can restore the checked backup.
"%BPY%" -B "%RC%\manifest_merge.py" --install "%EX%" "%INSTALL_TO%" "%CODE%" "%RC%\install_godot.bat" "%JOB%" "%R209_SHIP%" %UNB%
if errorlevel 1 goto bad
:done
echo Stage 7 done: PASS. The game's ship folder is %EX%
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 0
:bad
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 1
