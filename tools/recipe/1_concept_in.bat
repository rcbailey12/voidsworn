@echo off
rem Ship recipe, stage 1: concept in. Checks the concept image is in the repo (docs\ship_pipeline\concepts\SHIP.webp), starts the
rem ship's placement file (tools\recipe\ships\SHIP.json) from the template if there is none, makes the job folder
rem Downloads\voidsworn_test\recipe\SHIP\ and writes the concept there as a PNG with its outline (alpha).
rem env.bat installs Pillow into Blender's python first; this stage stops with FAILED if any step fails.
call "%~dp0env.bat"
if not exist "%REPO%\docs\ship_pipeline\concepts\%SHIP%.webp" (echo Stage 1 FAILED: no concept at docs\ship_pipeline\concepts\%SHIP%.webp. Add it first. & goto bad)
if exist "%RC%\ships\%SHIP%.json" goto have
set /p FAC=Faction id (corsair, voidsworn, ithar, deathless, chorus, hegemony): 
"%BPY%" "%RC%\ship.py" %SHIP% new %FAC%
if errorlevel 1 (echo Stage 1 FAILED: could not start ships\%SHIP%.json & goto bad)
:have
"%BPY%" "%RC%\ship.py" %SHIP% concept "%JOB%\concept.png"
if errorlevel 1 (echo Stage 1 FAILED: the concept PNG was not written. & goto bad)
if not exist "%JOB%\concept.png" (echo Stage 1 FAILED: the concept PNG was not written. & goto bad)
echo Stage 1 done: %JOB%
pause
exit /b 0
:bad
pause
exit /b 1
