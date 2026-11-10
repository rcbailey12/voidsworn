@echo off
rem Ship recipe, stage 5: the paint bake. The faction's paint (tools\blender\kits\FACTION\paint.py) and the shape reference's surface
rem grime are baked to texture atlases (hull: albedo, ORM, detail normal; parts: albedo, ORM) on the 5080, then the ship is rendered
rem at the concept camera (studio light and concept light) and at the fixed views. About 30 to 40 minutes.
rem The bake script is the ship json's "bake" (env.bat; default bakeAb6.py, which builds whichever hull module the json names).
rem Stops with FAILED (non-zero exit) when the bake or a render writes nothing.
call "%~dp0env.bat"
if not exist "%B0%" (echo Stage 5 FAILED: no shape reference at %B0%. Run stage 2 first. & goto bad)
"%B%" -b -P "%R%\%BAKE%" -- "%JOB%" "%B0%" none %CELL% 4096 64 > "%JOB%\log_bake.txt" 2>&1
findstr /L /c:"[209] %CELL% {" "%JOB%\log_bake.txt" > nul || (echo Stage 5 FAILED: the bake ^(%BAKE%^) wrote nothing. See %JOB%\log_bake.txt & goto bad)
"%B%" -b "%JOB%\%CELL%.blend" -P "%R%\render.py" -- "%JOB%\r" %CELL% > "%JOB%\log_render.txt" 2>&1
"%B%" -b "%JOB%\%CELL%.blend" -P "%R%\render.py" -- "%JOB%\r" %CELL% --views=concept --light=concept >> "%JOB%\log_render.txt" 2>&1
findstr /L /c:"RENDER DONE" "%JOB%\log_render.txt" > nul || (echo Stage 5 FAILED: the renders did not finish. See %JOB%\log_render.txt & goto bad)
"%B%" -b "%JOB%\%CELL%.blend" -P "%R%\close6.py" -- "%JOB%\close" %CELL% > "%JOB%\log_close.txt" 2>&1
if errorlevel 1 (echo Stage 5 FAILED: the close-ups failed. See %JOB%\log_close.txt & goto bad)
echo Stage 5 done: renders in %JOB%\r and %JOB%\close
pause
exit /b 0
:bad
pause
exit /b 1
