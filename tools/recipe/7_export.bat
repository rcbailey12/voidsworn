@echo off
rem Ship recipe, stage 7: the game export, automated (issue 209 round 7; FINDINGS R155, R156).
rem From the baked ship (stage 5) and the ship json, with no hand steps, this writes the game's ship folder into
rem Downloads\voidsworn_test\recipe\SHIP\export\CODE\ : CODE.glb (one ship node with a child node per hard point: hp_w per weapon
rem muzzle, hp_eng, hp_breach, hp_core) and the 2048 map set (export7.py). Then it reads the glb back and checks it
rem (check_export.py): FAIL when a weapon slot of the ship's data.js weapon list has no hard point, or a hard point is off the mesh.
rem Last, it proves the check itself can fail (check_export_selftest.py: three broken copies must all be refused).
rem It never copies into the game on its own. To install a checked export, set INSTALL_TO to a Godot project folder (the folder
rem that holds project.godot) before running this: the files it replaces are first copied to export\replaced_DATE\, and the old
rem ship's wreck and damage files are moved there too (they belong to the old hull). Nothing is deleted.
rem Set RECIPE_NOPAUSE=1 to run it from another job without the key press at the end.
call "%~dp0env.bat"
set EX=%JOB%\export\%CODE%
if not exist "%JOB%\%CELL%.blend" (echo Stage 7 FAILED: no baked ship at %JOB%\%CELL%.blend. Run stage 5 first. & goto bad)
if not exist "%EX%" mkdir "%EX%"
echo RUNNING > "%EX%\export_status.txt"
"%B%" -b "%JOB%\%CELL%.blend" -P "%RC%\export7.py" -- "%R209_SHIP%" "%EX%" maps=2048 > "%JOB%\log_export.txt" 2>&1
findstr /c:"[export7]" "%JOB%\log_export.txt"
findstr /b /c:"WRITTEN" "%EX%\export_status.txt" > nul
if errorlevel 1 (echo Stage 7 FAILED: the export was not written. See %JOB%\log_export.txt & goto bad)
"%BPY%" "%RC%\check_export.py" "%R209_SHIP%" "%EX%" > "%JOB%\log_export_check.txt" 2>&1
set CHK=%errorlevel%
type "%JOB%\log_export_check.txt"
if not "%CHK%"=="0" (echo CHECK FAILED > "%EX%\export_status.txt" & echo Stage 7 FAILED: %EX% is not a game ship folder. Nothing was installed. & goto bad)
"%BPY%" "%RC%\check_export_selftest.py" "%R209_SHIP%" "%EX%" > "%JOB%\log_export_selftest.txt" 2>&1
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
echo Installed into %SH% (what was there before is in %OLD%)
:done
echo Stage 7 done: PASS. The game's ship folder is %EX%
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 0
:bad
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 1
