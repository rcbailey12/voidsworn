@echo off
rem Ship recipe, stage 5: the paint bake. The faction's paint (tools\blender\kits\FACTION\paint.py) and the shape reference's surface
rem grime are baked to texture atlases (hull: albedo, ORM, detail normal; parts: albedo, ORM) on the 5080, then the ship is rendered
rem at the concept camera (studio light and concept light) and at the fixed views. About 30 to 40 minutes.
rem The bake script is the ship json's "bake" (env.bat; default bakeAb6.py, which builds whichever hull module the json names).
rem Stops with FAILED (non-zero exit) when the bake or a render writes nothing.
rem Issue 592: "bake": "none" in the ship json means this ship has no paint stack yet. The stage then bakes nothing: stage 4's
rem build goes on as the stage 5 ship, unpainted, and stage 7 exports it as an unbaked test export (said so in its files).
rem Issue 601: "bake": "stack" paints a ship built from a build sheet with its faction kit's paint stack (env.bat turns it into
rem bake_sheet.py: masks baked from the ship's own geometry, procedural layers, the faction's trim sheet and decals, colours
rem sampled from the concept, never the concept projected). A faction with no stack yet goes the "none" way, said so below.
call "%~dp0env.bat"
if not defined SHEET if not exist "%B0%" (echo Stage 5 FAILED: no shape reference at %B0%. Run stage 2 first. & goto bad)
if /i not "%BAKE%"=="none" goto bake
if not exist "%JOB%\build\%CELL%.blend" (echo Stage 5 FAILED: no stage 4 build at %JOB%\build\%CELL%.blend. Run stage 4 first. & goto bad)
copy /y "%JOB%\build\%CELL%.blend" "%JOB%\%CELL%.blend" > nul
if not "%STACK_NOTE%"=="" echo Stage 5: %STACK_NOTE%
echo Stage 5: no paint stack for this ship yet ^(bake none^): the unpainted stage 4 build goes on.
goto baked
:bake
set "TMO_STEP=recipe 5 paint bake"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_BAKE_CAP% "%B%" -b --python-exit-code 1 -P "%R%\%BAKE%" -- "%JOB%" "%B0%" none %CELL% 4096 64 > "%JOB%\log_bake.txt" 2>&1
if not "%ERRORLEVEL%"=="0" (echo Stage 5 FAILED: the bake ^(%BAKE%^) exited code %ERRORLEVEL%. See %JOB%\log_bake.txt & goto bad)
rem Issue 726: Cycles can fail shader compilation while Blender still exits zero and writes the completion marker.
findstr /i /c:"out of SVM stack space" /c:"failed to compile" /c:"shader compilation failed" /c:"shader compilation error" /c:"shader compile error" /c:"error compiling" "%JOB%\log_bake.txt" > nul
if not errorlevel 1 (echo Stage 5 FAILED: Cycles could not compile a bake shader. See %JOB%\log_bake.txt & goto bad)
findstr /L /c:"[209] %CELL% {" "%JOB%\log_bake.txt" > nul || (echo Stage 5 FAILED: the bake ^(%BAKE%^) wrote nothing. See %JOB%\log_bake.txt & goto bad)
rem issue 601: every surface seen from outside carries the stack: no inside room colour and no unpainted surface in six views
set "TMO_STEP=recipe 5 surface check"
if /i "%BAKE%"=="bake_sheet.py" call "%REPO%\tools\pc\tmo.bat" %RECIPE_CHECK_CAP% "%B%" -b --python-exit-code 1 "%JOB%\%CELL%.blend" -P "%RC%\surface_check.py" -- "%JOB%\surface" > "%JOB%\log_surface.txt" 2>&1
if /i "%BAKE%"=="bake_sheet.py" if not "%ERRORLEVEL%"=="0" (echo Stage 5 FAILED: the surface check exited code %ERRORLEVEL%. See %JOB%\log_surface.txt & goto bad)
if /i "%BAKE%"=="bake_sheet.py" (findstr /b /c:"PASS surface check" "%JOB%\log_surface.txt" || (findstr /c:"surface check" /c:"seen from outside" "%JOB%\log_surface.txt" & echo Stage 5 FAILED: surfaces seen from outside without the paint stack. See %JOB%\log_surface.txt & goto bad))
if /i "%BAKE%"=="bake_sheet.py" if exist "%JOB%\density.json" "%BPY%" -c "import json,sys;d=json.load(open(sys.argv[1]))['summary'];print('Stage 5 R224 density (reported, not a pass bar): paint flags',len(d['paint_flags']),'mesh flags',len(d['mesh_flags']));[print('  ',f) for f in d['paint_flags']+d['mesh_flags']]" "%JOB%\density.json"
:baked
rem the ship's own fitted concept camera (stage 3), so the concept side still belongs to this ship and not to C15s_23
set CAMJ=
for /f "usebackq delims=" %%L in (`""%BPY%" "%RC%\ship.py" %SHIP% get concept_camera"`) do set CAMJ=%%L
if not "%CAMJ%"=="" set CAMJ=%REPO%\%CAMJ%
if "%CAMJ%"=="" if exist "%JOB%\concept_camera.json" set CAMJ=%JOB%\concept_camera.json
set CAMARG=
if not "%CAMJ%"=="" set CAMARG=--cam=%CAMJ%
rem Sheet ships have authored seams, not the legacy four-piece break preview's mandatory longitudinal cut.
set PAINTVIEWS=
if not "%SHEET%"=="" set PAINTVIEWS=--views=concept,hero,side,top,below,battle
rem Issue 873: one log per render pass, and every pass is checked on its own exit code and on its own RENDER DONE line.
rem A failed or silent second or third pass can no longer hide behind the first pass's line.
set "TMO_STEP=recipe 5 studio renders"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_RENDER_CAP% "%B%" -b --python-exit-code 1 "%JOB%\%CELL%.blend" -P "%R%\render.py" -- "%JOB%\r" %CELL% "%CAMARG%" %PAINTVIEWS% > "%JOB%\log_render.txt" 2>&1
if not "%ERRORLEVEL%"=="0" (echo Stage 5 FAILED: render pass 1 ^(default views^) exited code %ERRORLEVEL%. See %JOB%\log_render.txt & goto bad)
findstr /L /c:"RENDER DONE" "%JOB%\log_render.txt" > nul || (echo Stage 5 FAILED: render pass 1 ^(default views^) wrote no RENDER DONE. See %JOB%\log_render.txt & goto bad)
set "TMO_STEP=recipe 5 concept render"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_RENDER_CAP% "%B%" -b --python-exit-code 1 "%JOB%\%CELL%.blend" -P "%R%\render.py" -- "%JOB%\r" %CELL% --views=concept --light=concept "%CAMARG%" > "%JOB%\log_render_concept.txt" 2>&1
if not "%ERRORLEVEL%"=="0" (echo Stage 5 FAILED: render pass 2 ^(concept light^) exited code %ERRORLEVEL%. See %JOB%\log_render_concept.txt & goto bad)
findstr /L /c:"RENDER DONE" "%JOB%\log_render_concept.txt" > nul || (echo Stage 5 FAILED: render pass 2 ^(concept light^) wrote no RENDER DONE. See %JOB%\log_render_concept.txt & goto bad)
rem Issue 363: the far side still, so paint is judged away from the concept camera too (R160 point (f)). The underside is a
rem default view; the starboard side (the side the concept camera does not see) is on request only in render.py.
set "TMO_STEP=recipe 5 far-side renders"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_RENDER_CAP% "%B%" -b --python-exit-code 1 "%JOB%\%CELL%.blend" -P "%R%\render.py" -- "%JOB%\r" %CELL% --views=side_s,hero_s > "%JOB%\log_render_far.txt" 2>&1
if not "%ERRORLEVEL%"=="0" (echo Stage 5 FAILED: render pass 3 ^(far side^) exited code %ERRORLEVEL%. See %JOB%\log_render_far.txt & goto bad)
findstr /L /c:"RENDER DONE" "%JOB%\log_render_far.txt" > nul || (echo Stage 5 FAILED: render pass 3 ^(far side^) wrote no RENDER DONE. See %JOB%\log_render_far.txt & goto bad)
if defined SHEET goto skip_close
set "TMO_STEP=recipe 5 close-up renders"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_RENDER_CAP% "%B%" -b --python-exit-code 1 "%JOB%\%CELL%.blend" -P "%R%\close6.py" -- "%JOB%\close" %CELL% > "%JOB%\log_close.txt" 2>&1
if not "%ERRORLEVEL%"=="0" (echo Stage 5 FAILED: the close-ups exited code %ERRORLEVEL%. See %JOB%\log_close.txt & goto bad)
goto close_done
:skip_close
echo Stage 5: skipped C15s close-ups for sheet ship %SHIP%. > "%JOB%\log_close.txt"
type "%JOB%\log_close.txt"
:close_done
rem Issue 363: the blink sheet, and the standing checks for paint sides, texture licences and light sizes.
"%BPY%" "%RC%\blink.py" "%JOB%\concept.png" "%JOB%\r\%CELL%_concept_cl.png" "%JOB%\bow_blink.gif" > "%JOB%\log_blink.txt" 2>&1
if errorlevel 1 (type "%JOB%\log_blink.txt" & echo Stage 5 FAILED: the blink sheet was not written. See %JOB%\log_blink.txt & goto bad)
type "%JOB%\log_blink.txt"
for %%C in (paint licences lights) do (
  "%BPY%" "%RC%\standing.py" %%C --ship "%R209_SHIP%" --job "%JOB%" > "%JOB%\log_standing_%%C.txt" 2>&1
  if errorlevel 1 (type "%JOB%\log_standing_%%C.txt" & echo Stage 5 FAILED: the standing %%C check did not pass. See %JOB%\log_standing_%%C.txt & goto bad)
  type "%JOB%\log_standing_%%C.txt"
)
if defined SHEET (echo Stage 5 done: renders in %JOB%\r) else (echo Stage 5 done: renders in %JOB%\r and %JOB%\close)
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 0
:bad
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 1
