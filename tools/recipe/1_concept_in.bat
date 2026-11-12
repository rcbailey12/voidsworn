@echo off
rem Ship recipe, stage 1: concept in. Checks the concept image is in the repo (docs\ship_pipeline\concepts\SHIP.webp), starts the
rem ship's placement file (tools\recipe\ships\SHIP.json) from the template if there is none, makes the job folder
rem Downloads\voidsworn_test\recipe\SHIP\ and writes the concept there as a PNG with its outline (alpha).
rem A ship whose json already exists reads its concept from the json ("concept"): for a ship built from a build sheet that
rem is the accepted concept picture the sheet was designed from (issue 592), and ship.py cuts it out and squares it.
rem env.bat installs Pillow into Blender's python first; this stage stops with FAILED if any step fails.
call "%~dp0env.bat"
if exist "%RC%\ships\%SHIP%.json" goto have
if not exist "%REPO%\docs\ship_pipeline\concepts\%SHIP%.webp" (echo Stage 1 FAILED: no concept at docs\ship_pipeline\concepts\%SHIP%.webp and no ships\%SHIP%.json. Add one first. & goto bad)
set /p FAC=Faction id (corsair, voidsworn, ithar, deathless, chorus, hegemony): 
"%BPY%" "%RC%\ship.py" %SHIP% new %FAC%
if errorlevel 1 (echo Stage 1 FAILED: could not start ships\%SHIP%.json & goto bad)
:have
"%BPY%" "%RC%\ship.py" %SHIP% concept "%JOB%\concept.png"
if errorlevel 1 (echo Stage 1 FAILED: the concept PNG was not written. & goto bad)
if not exist "%JOB%\concept.png" (echo Stage 1 FAILED: the concept PNG was not written. & goto bad)
echo Stage 1 done: %JOB%
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 0
:bad
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 1
