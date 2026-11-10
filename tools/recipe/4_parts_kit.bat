@echo off
rem Ship recipe, stage 4: the faction parts kit. Builds the hull with the faction kit's parts at the sockets in ships\SHIP.json
rem (tools\blender\kits\FACTION\kit.py; shared plumbing in kits\shared), audits it (nothing floats, nothing crosses the build's own
rem break lines, no gun aimed backward or into the ship against its mount normal), proves the audit can fail (audit_selftest.py),
rem re-scores the outline gate with the parts on, and renders clay close-ups at the concept camera.
rem Stops with FAILED (non-zero exit) when the build is missing, the audit lists any problem or crossing, or the self-test fails.
rem The outline gate result is printed and decides the exit code, but the close-ups are still made so the shape can be judged.
call "%~dp0env.bat"
if not exist "%JOB%\build" mkdir "%JOB%\build"
"%B%" -b -P "%R%\%HULL%.py" -- "%JOB%\build" %CELL% > "%JOB%\log_build.txt" 2>&1
findstr /L /c:"[209] {" "%JOB%\log_build.txt" > nul || (echo Stage 4 FAILED: the build did not write %JOB%\build\%CELL%.blend. See %JOB%\log_build.txt & goto bad)
"%B%" -b "%JOB%\build\%CELL%.blend" -P "%RC%\audit.py" -- "%JOB%\audit.json" > "%JOB%\log_audit.txt" 2>&1
set AUD=%errorlevel%
if not exist "%JOB%\audit.json" (echo Stage 4 FAILED: the audit did not run. See %JOB%\log_audit.txt & goto bad)
type "%JOB%\audit.json"
if not "%AUD%"=="0" (echo Stage 4 FAILED: the audit found problems ^(audit.json^). & goto bad)
"%B%" -b "%JOB%\build\%CELL%.blend" -P "%RC%\audit_selftest.py" -- "%JOB%\audit_selftest" > "%JOB%\log_audit_selftest.txt" 2>&1
if errorlevel 1 (echo Stage 4 FAILED: the audit did not refuse a broken build. See %JOB%\log_audit_selftest.txt & goto bad)
"%B%" -b -P "%R%\sil_dump.py" -- "%JOB%\%CELL%.npz" build %HULL% %CELL% > "%JOB%\log_sildump.txt" 2>&1
findstr /L /c:"[sil] dumped" "%JOB%\log_sildump.txt" > nul || (echo Stage 4 FAILED: the outline dump failed. See %JOB%\log_sildump.txt & goto bad)
set CAMJ=
for /f "usebackq delims=" %%L in (`"%BPY%" "%RC%\ship.py" %SHIP% get concept_camera`) do set CAMJ=%%L
if "%CAMJ%"=="" (set CAMJ=%JOB%\concept_camera.json) else (set CAMJ=%REPO%\%CAMJ%)
"%BPY%" "%R%\silhouette4.py" score "%JOB%\concept.png" "%CAMJ%" "%JOB%\sil" %CELL%="%JOB%\%CELL%.npz" > "%JOB%\log_sil.txt" 2>&1
if errorlevel 1 (echo Stage 4 FAILED: the outline could not be scored. See %JOB%\log_sil.txt & goto bad)
"%BPY%" "%RC%\ship.py" %SHIP% gate "%JOB%\sil\silhouette_scores.json"
set GATE=%errorlevel%
"%B%" -b "%JOB%\build\%CELL%.blend" -P "%R%\close6.py" -- "%JOB%\clay" %CELL% 32 > "%JOB%\log_clay.txt" 2>&1
echo Close-ups in %JOB%\clay
if not "%GATE%"=="0" (echo Stage 4: audit PASS, outline gate FAILED. & goto bad)
echo Stage 4 done: audit PASS, outline gate PASS
pause
exit /b 0
:bad
pause
exit /b 1
