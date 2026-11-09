@echo off
rem Ship recipe, stage 5: the paint bake. The faction's paint (tools\blender\kits\FACTION\paint.py) and the shape reference's surface
rem grime are baked to texture atlases (hull: albedo, ORM, detail normal; parts: albedo, ORM) on the 5080, then the ship is rendered
rem at the concept camera (studio light and concept light) and at the fixed views. About 30 to 40 minutes.
call "%~dp0env.bat"
"%B%" -b -P "%R%\bakeAb6.py" -- "%JOB%" "%B0%" none %CELL% 4096 64 > "%JOB%\log_bake.txt" 2>&1
if not exist "%JOB%\%CELL%.blend" (echo Stage 5 FAILED: see %JOB%\log_bake.txt & pause & exit /b 1)
"%B%" -b "%JOB%\%CELL%.blend" -P "%R%\render.py" -- "%JOB%\r" %CELL% > "%JOB%\log_render.txt" 2>&1
"%B%" -b "%JOB%\%CELL%.blend" -P "%R%\render.py" -- "%JOB%\r" %CELL% --views=concept --light=concept >> "%JOB%\log_render.txt" 2>&1
"%B%" -b "%JOB%\%CELL%.blend" -P "%R%\close6.py" -- "%JOB%\close" %CELL% > "%JOB%\log_close.txt" 2>&1
echo Stage 5 done: renders in %JOB%\r and %JOB%\close
pause
