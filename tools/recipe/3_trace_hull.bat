@echo off
rem Ship recipe, stage 3: the traced hull and the outline overlap. Slices the shape reference every 0.02 of the ship's length and fits
rem one clean faceted section to each slice (b0trace.py), tunes the hull module's numbers on the concept outline with a small pull
rem toward the shape reference (tune5.py, the slow step: about 10 minutes a run), then scores the outline at the concept's own
rem camera. The overlap is REPORTED against the ship's outline_gate (90 percent); it is not a pass bar (RULEBOOK 5.8).
rem Refuses to run without the shape reference (stage 2); every step that fails stops the stage with FAILED and a non-zero exit.
call "%~dp0env.bat"
if not exist "%B0%" (echo Stage 3 FAILED: no shape reference at %B0%. Run stage 2 first. & goto bad)
if "%HULL%"=="" (echo Stage 3 FAILED: no hull module in ships\%SHIP%.json. Copy tools\blender\r209\armA5.py as the ship's hull module, set its block table to the concept's blocks, and name it in the json. & goto bad)
"%BPY%" "%RC%\ship.py" %SHIP% concept "%JOB%\concept.png"
if errorlevel 1 (echo Stage 3 FAILED: the concept PNG was not written. & goto bad)
"%B%" -b -P "%R%\sil_dump.py" -- "%JOB%\b0.npz" b0 "%B0%" > "%JOB%\log_b0dump.txt" 2>&1
findstr /L /c:"[sil] dumped" "%JOB%\log_b0dump.txt" > nul || (echo Stage 3 FAILED: the shape reference could not be read. See %JOB%\log_b0dump.txt & goto bad)
for /f "usebackq delims=" %%L in (`"%BPY%" "%RC%\ship.py" %SHIP% get concept_camera`) do set CAMJ=%%L
if "%CAMJ%"=="" (set CAMJ=%JOB%\concept_camera.json & "%BPY%" "%R%\silhouette4.py" fit "%JOB%\concept.png" "%JOB%\b0.npz" "%JOB%\concept_camera.json") else (set CAMJ=%REPO%\%CAMJ%)
"%BPY%" "%R%\b0trace.py" slices "%JOB%\b0.npz" "%JOB%\slices.npz" > "%JOB%\log_trace.txt" 2>&1
if errorlevel 1 (echo Stage 3 FAILED: the trace failed. See %JOB%\log_trace.txt & goto bad)
if not "%R209_TUNE_JSON%"=="" goto tuned
echo Tuning the hull on the concept outline (about 10 minutes)...
"%B%" -b -P "%R%\tune5.py" -- "%JOB%\concept.png" "%CAMJ%" "%JOB%\b0.npz" "%JOB%\tune.json" 2 512 .25 > "%JOB%\log_tune.txt" 2>&1
if not exist "%JOB%\tune.json" (echo Stage 3 FAILED: the tune wrote nothing. See %JOB%\log_tune.txt & goto bad)
set R209_TUNE_JSON=%JOB%\tune.json
echo Tuned numbers: %JOB%\tune.json (commit it beside the hull module and name it as "tune" in ships\%SHIP%.json to keep it)
:tuned
"%B%" -b -P "%R%\sil_dump.py" -- "%JOB%\%CELL%.npz" build %HULL% %CELL% > "%JOB%\log_sildump.txt" 2>&1
findstr /L /c:"[sil] dumped" "%JOB%\log_sildump.txt" > nul || (echo Stage 3 FAILED: the hull could not be built. See %JOB%\log_sildump.txt & goto bad)
"%BPY%" "%R%\silhouette4.py" score "%JOB%\concept.png" "%CAMJ%" "%JOB%\sil" %CELL%="%JOB%\%CELL%.npz" > "%JOB%\log_sil.txt" 2>&1
if errorlevel 1 (echo Stage 3 FAILED: the outline could not be scored. See %JOB%\log_sil.txt & goto bad)
rem Issue 363: the standing checks the recipe keeps (outside audit pass 2, finding 13): the score per third and the inner
rem edge check, recorded beside the whole outline score. The overlap is reported, not a pass bar (RULEBOOK 5.8).
"%BPY%" "%R%\outline_thirds.py" "%JOB%\concept.png" "%CAMJ%" "%JOB%\sil" %CELL%="%JOB%\%CELL%.npz" > "%JOB%\log_thirds.txt" 2>&1
if errorlevel 1 (echo Stage 3 FAILED: the outline per third and inner edge check did not run. See %JOB%\log_thirds.txt & goto bad)
"%BPY%" "%RC%\standing.py" outline --ship "%R209_SHIP%" --job "%JOB%" > "%JOB%\log_standing.txt" 2>&1
if errorlevel 1 (type "%JOB%\log_standing.txt" & echo Stage 3 FAILED: the standing outline record is incomplete. See %JOB%\log_standing.txt & goto bad)
type "%JOB%\log_standing.txt"
"%BPY%" "%RC%\ship.py" %SHIP% gate "%JOB%\sil\silhouette_scores.json"
set GATE=%errorlevel%
echo The overlay is %JOB%\sil\sil_%CELL%.png (green both, red concept only, yellow ship only).
if not "%GATE%"=="0" (echo Stage 3 FAILED: the outline score could not be read. & goto bad)
echo Stage 3 done: PASS, the outline overlap is reported above (not a pass bar, RULEBOOK 5.8)
pause
exit /b 0
:bad
pause
exit /b 1
