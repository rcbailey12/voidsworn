@echo off
rem Ship recipe, stage 6: LOD. Exports the hand LOD chain (lod0 to lod3, one shared set of atlases; small parts drop out by size,
rem export3.py) and measures it in Godot (twenty copies at the battle camera, LOD off, Godot auto and the hand chain; 1080p and 3D at
rem 4K). Costs are reported, never capped (R111). Stops with FAILED (non-zero exit) when the export or the bench writes nothing.
rem Issue 592: the LOD chain is an analysis product. The game ships stage 7's export (one full-detail ship mesh, no LOD chain);
rem lod0 here is that same geometry, so the bench's lod0 numbers are the shipped mesh's in the studio scene. The binding cost
rem is the #207 scene gate with the installed ship (RULEBOOK 3.9), run after stage 7. The bench draws the ship at its own class
rem length (LEN, from the ship json or its build sheet), never at C15s_23's 14.5.
call "%~dp0env.bat"
if "%LEN%"=="" (echo Stage 6 FAILED: ships\%SHIP%.json gives no class length ^(length_world, or its build sheet's LENGTH^). & goto bad)
if not exist "%JOB%\%CELL%.blend" (echo Stage 6 FAILED: no baked ship at %JOB%\%CELL%.blend. Run stage 5 first. & goto bad)
if not exist "%JOB%\glb" mkdir "%JOB%\glb"
if not exist "%JOB%\godot\proj" mkdir "%JOB%\godot\proj"
"%B%" -b "%JOB%\%CELL%.blend" -P "%R%\export3.py" -- "%JOB%\glb\%CELL%.glb" > "%JOB%\log_lod.txt" 2>&1
findstr /L /c:"[209] export" "%JOB%\log_lod.txt" > nul || (echo Stage 6 FAILED: the LOD export wrote nothing. See %JOB%\log_lod.txt & goto bad)
copy /y "%R%\godot\project.godot" "%JOB%\godot\proj\" > nul
copy /y "%R%\godot\bench209r3.gd" "%JOB%\godot\proj\" > nul
call "%REPO%\tools\pc\tmo.bat" 1800 "%GD%" --path "%JOB%\godot\proj" --resolution 1920x1080 --script res://bench209r3.gd -- "%JOB%\glb" "%JOB%\godot" %CELL% 2 length=%LEN% > "%JOB%\log_godot.txt" 2>&1
findstr /L /c:"BENCH DONE" "%JOB%\log_godot.txt" > nul || (echo Stage 6 FAILED: the Godot bench did not finish. See %JOB%\log_godot.txt & goto bad)
echo Stage 6 done: %JOB%\glb\%CELL%.glb and %JOB%\godot
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 0
:bad
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 1
