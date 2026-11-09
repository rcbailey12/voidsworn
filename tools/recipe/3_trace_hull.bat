@echo off
rem Ship recipe, stage 3: the traced hull and the outline gate. Slices the shape reference every 0.02 of the ship's length and fits
rem one clean faceted section to each slice (b0trace.py), tunes the hull module's numbers on the concept outline with a small pull
rem toward the shape reference (tune5.py, the slow step: about 10 minutes a run), then scores the outline at the concept's own
rem camera. The gate is the ship's outline_gate (90 percent): FAIL means the shape is not ready for parts.
rem First run only: installs scipy and Pillow into Blender's own python (free, about a minute).
call "%~dp0env.bat"
"%BPY%" -c "import scipy, PIL" 2> nul || ("%BPY%" -m ensurepip & "%BPY%" -m pip install scipy pillow)
if "%HULL%"=="" (echo No hull module in ships\%SHIP%.json. Copy tools\blender\r209\armA5.py as the ship's hull module, set its block table to the concept's blocks, and name it in the json. & pause & exit /b 1)
"%BPY%" "%RC%\ship.py" %SHIP% concept "%JOB%\concept.png"
"%B%" -b -P "%R%\sil_dump.py" -- "%JOB%\b0.npz" b0 "%B0%" > "%JOB%\log_b0dump.txt" 2>&1
for /f "usebackq delims=" %%L in (`"%BPY%" "%RC%\ship.py" %SHIP% get concept_camera`) do set CAMJ=%%L
if "%CAMJ%"=="" (set CAMJ=%JOB%\concept_camera.json & "%BPY%" "%R%\silhouette4.py" fit "%JOB%\concept.png" "%JOB%\b0.npz" "%JOB%\concept_camera.json") else (set CAMJ=%REPO%\%CAMJ%)
"%BPY%" "%R%\b0trace.py" slices "%JOB%\b0.npz" "%JOB%\slices.npz" > "%JOB%\log_trace.txt" 2>&1
if not "%R209_TUNE_JSON%"=="" goto tuned
echo Tuning the hull on the concept outline (about 10 minutes)...
"%B%" -b -P "%R%\tune5.py" -- "%JOB%\concept.png" "%CAMJ%" "%JOB%\b0.npz" "%JOB%\tune.json" 2 512 .25 > "%JOB%\log_tune.txt" 2>&1
set R209_TUNE_JSON=%JOB%\tune.json
echo Tuned numbers: %JOB%\tune.json (commit it beside the hull module and name it as "tune" in ships\%SHIP%.json to keep it)
:tuned
"%B%" -b -P "%R%\sil_dump.py" -- "%JOB%\%CELL%.npz" build %HULL% %CELL% > "%JOB%\log_sildump.txt" 2>&1
"%BPY%" "%R%\silhouette4.py" score "%JOB%\concept.png" "%CAMJ%" "%JOB%\sil" %CELL%="%JOB%\%CELL%.npz" > "%JOB%\log_sil.txt" 2>&1
"%BPY%" "%RC%\ship.py" %SHIP% gate "%JOB%\sil\silhouette_scores.json"
echo The overlay is %JOB%\sil\sil_%CELL%.png (green both, red concept only, yellow ship only).
pause
