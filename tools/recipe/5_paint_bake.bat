@echo off
rem Ship recipe, stage 5: the paint bake. The faction's paint (tools\blender\kits\FACTION\paint.py) and the shape reference's surface
rem grime are baked to texture atlases (hull: albedo, ORM, detail normal; parts: albedo, ORM) on the 5080, then the ship is rendered
rem at the concept camera (studio light and concept light) and at the fixed views. About 30 to 40 minutes.
rem The bake script is the ship json's "bake" (env.bat; default bakeAb6.py, which builds whichever hull module the json names).
rem Stops with FAILED (non-zero exit) when the bake or a render writes nothing.
rem Issue 592: "bake": "none" in the ship json means this ship has no paint stack yet. The stage then bakes nothing: stage 4's
rem build goes on as the stage 5 ship, unpainted, and stage 7 exports it as an unbaked test export (said so in its files).
call "%~dp0env.bat"
if not exist "%B0%" (echo Stage 5 FAILED: no shape reference at %B0%. Run stage 2 first. & goto bad)
if /i not "%BAKE%"=="none" goto bake
if not exist "%JOB%\build\%CELL%.blend" (echo Stage 5 FAILED: no stage 4 build at %JOB%\build\%CELL%.blend. Run stage 4 first. & goto bad)
copy /y "%JOB%\build\%CELL%.blend" "%JOB%\%CELL%.blend" > nul
echo Stage 5: no paint stack for this ship yet ^(bake none^): the unpainted stage 4 build goes on.
goto baked
:bake
"%B%" -b -P "%R%\%BAKE%" -- "%JOB%" "%B0%" none %CELL% 4096 64 > "%JOB%\log_bake.txt" 2>&1
findstr /L /c:"[209] %CELL% {" "%JOB%\log_bake.txt" > nul || (echo Stage 5 FAILED: the bake ^(%BAKE%^) wrote nothing. See %JOB%\log_bake.txt & goto bad)
:baked
rem the ship's own fitted concept camera (stage 3), so the concept side still belongs to this ship and not to C15s_23
set CAMJ=
for /f "usebackq delims=" %%L in (`""%BPY%" "%RC%\ship.py" %SHIP% get concept_camera"`) do set CAMJ=%%L
if not "%CAMJ%"=="" set CAMJ=%REPO%\%CAMJ%
if "%CAMJ%"=="" if exist "%JOB%\concept_camera.json" set CAMJ=%JOB%\concept_camera.json
set CAMARG=
if not "%CAMJ%"=="" set CAMARG=--cam=%CAMJ%
"%B%" -b "%JOB%\%CELL%.blend" -P "%R%\render.py" -- "%JOB%\r" %CELL% "%CAMARG%" > "%JOB%\log_render.txt" 2>&1
"%B%" -b "%JOB%\%CELL%.blend" -P "%R%\render.py" -- "%JOB%\r" %CELL% --views=concept --light=concept "%CAMARG%" >> "%JOB%\log_render.txt" 2>&1
rem Issue 363: the far side still, so paint is judged away from the concept camera too (R160 point (f)). The underside is a
rem default view; the starboard side (the side the concept camera does not see) is on request only in render.py.
"%B%" -b "%JOB%\%CELL%.blend" -P "%R%\render.py" -- "%JOB%\r" %CELL% --views=side_s,hero_s >> "%JOB%\log_render.txt" 2>&1
findstr /L /c:"RENDER DONE" "%JOB%\log_render.txt" > nul || (echo Stage 5 FAILED: the renders did not finish. See %JOB%\log_render.txt & goto bad)
"%B%" -b "%JOB%\%CELL%.blend" -P "%R%\close6.py" -- "%JOB%\close" %CELL% > "%JOB%\log_close.txt" 2>&1
if errorlevel 1 (echo Stage 5 FAILED: the close-ups failed. See %JOB%\log_close.txt & goto bad)
rem Issue 363: the blink sheet, and the standing checks for paint sides, texture licences and light sizes.
"%BPY%" "%RC%\blink.py" "%JOB%\concept.png" "%JOB%\r\%CELL%_concept_cl.png" "%JOB%\bow_blink.gif" > "%JOB%\log_blink.txt" 2>&1
if errorlevel 1 (type "%JOB%\log_blink.txt" & echo Stage 5 FAILED: the blink sheet was not written. See %JOB%\log_blink.txt & goto bad)
type "%JOB%\log_blink.txt"
for %%C in (paint licences lights) do (
  "%BPY%" "%RC%\standing.py" %%C --ship "%R209_SHIP%" --job "%JOB%" > "%JOB%\log_standing_%%C.txt" 2>&1
  if errorlevel 1 (type "%JOB%\log_standing_%%C.txt" & echo Stage 5 FAILED: the standing %%C check did not pass. See %JOB%\log_standing_%%C.txt & goto bad)
  type "%JOB%\log_standing_%%C.txt"
)
echo Stage 5 done: renders in %JOB%\r and %JOB%\close
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 0
:bad
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 1
