@echo off
rem Ship recipe, stage 6: LOD. Exports the hand LOD chain (lod0 to lod3, one shared set of atlases; small parts drop out by size,
rem export3.py) and measures it in Godot (twenty copies at the battle camera, LOD off, Godot auto and the hand chain; 1080p and 3D at
rem 4K). Costs are reported, never capped (R111).
call "%~dp0env.bat"
if not exist "%JOB%\glb" mkdir "%JOB%\glb"
if not exist "%JOB%\godot\proj" mkdir "%JOB%\godot\proj"
"%B%" -b "%JOB%\%CELL%.blend" -P "%R%\export3.py" -- "%JOB%\glb\%CELL%.glb" > "%JOB%\log_lod.txt" 2>&1
copy /y "%R%\godot\project.godot" "%JOB%\godot\proj\" > nul
copy /y "%R%\godot\bench209r3.gd" "%JOB%\godot\proj\" > nul
"%GD%" --path "%JOB%\godot\proj" --resolution 1920x1080 --script res://bench209r3.gd -- "%JOB%\glb" "%JOB%\godot" %CELL% 2 > "%JOB%\log_godot.txt" 2>&1
echo Stage 6 done: %JOB%\glb\%CELL%.glb and %JOB%\godot
pause
