@echo off
rem Ship recipe, stage 4: the faction parts kit. Builds the hull with the faction kit's parts at the sockets in ships\SHIP.json
rem (tools\blender\kits\FACTION\kit.py; shared plumbing in kits\shared), audits it (nothing floats, nothing crosses a break line, no gun
rem aimed backward or into the ship), re-scores the outline gate with the parts on, and renders clay close-ups at the concept camera.
call "%~dp0env.bat"
"%B%" -b -P "%R%\%HULL%.py" -- "%JOB%\build" %CELL% > "%JOB%\log_build.txt" 2>&1
"%B%" -b "%JOB%\build\%CELL%.blend" -P "%RC%\audit.py" -- "%JOB%\audit.json" > "%JOB%\log_audit.txt" 2>&1
type "%JOB%\audit.json"
"%B%" -b -P "%R%\sil_dump.py" -- "%JOB%\%CELL%.npz" build %HULL% %CELL% > "%JOB%\log_sildump.txt" 2>&1
set CAMJ=
for /f "usebackq delims=" %%L in (`"%BPY%" "%RC%\ship.py" %SHIP% get concept_camera`) do set CAMJ=%%L
if "%CAMJ%"=="" (set CAMJ=%JOB%\concept_camera.json) else (set CAMJ=%REPO%\%CAMJ%)
"%BPY%" "%R%\silhouette4.py" score "%JOB%\concept.png" "%CAMJ%" "%JOB%\sil" %CELL%="%JOB%\%CELL%.npz" > "%JOB%\log_sil.txt" 2>&1
"%BPY%" "%RC%\ship.py" %SHIP% gate "%JOB%\sil\silhouette_scores.json"
"%B%" -b "%JOB%\build\%CELL%.blend" -P "%R%\close6.py" -- "%JOB%\clay" %CELL% 32 > "%JOB%\log_clay.txt" 2>&1
echo Close-ups in %JOB%\clay
pause
