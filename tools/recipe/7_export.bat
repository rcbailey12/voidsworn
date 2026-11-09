@echo off
rem Ship recipe, stage 7: export for the game. Copies the LOD glb and its atlases to Downloads\voidsworn_test\recipe\export\SHIP\ for the
rem Godot import. Not yet automated: the game's A4 ship format (hard points hp_w, hp_eng, hp_breach, hp_core, wreck and damage glbs,
rem the 2048 map set in godot\assets\ships\manifest.json) and the R116 scene gate; that conversion is its own board job (issue 209
rem round 5 README, section 6). This stage stops there and says so.
call "%~dp0env.bat"
set EX=%V%\recipe\export\%SHIP%
if not exist "%EX%" mkdir "%EX%"
copy /y "%JOB%\glb\%CELL%*.*" "%EX%\" > nul
echo Copied the LOD glb to %EX%. Next: the A4 ship-format conversion and the scene gate (a board job, not automated yet).
pause
