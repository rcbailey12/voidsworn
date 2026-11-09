@echo off
rem Ship recipe, stage 1: concept in. Checks the concept image is in the repo (docs\ship_pipeline\concepts\SHIP.webp), starts the
rem ship's placement file (tools\recipe\ships\SHIP.json) from the template if there is none, makes the job folder
rem Downloads\voidsworn_test\recipe\SHIP\ and writes the concept there as a PNG with its outline (alpha).
call "%~dp0env.bat"
if not exist "%REPO%\docs\ship_pipeline\concepts\%SHIP%.webp" (echo No concept at docs\ship_pipeline\concepts\%SHIP%.webp. Add it first. & pause & exit /b 1)
if exist "%RC%\ships\%SHIP%.json" goto have
set /p FAC=Faction id (corsair, voidsworn, ithar, deathless, chorus, hegemony): 
"%BPY%" "%RC%\ship.py" %SHIP% new %FAC%
:have
"%BPY%" "%RC%\ship.py" %SHIP% concept "%JOB%\concept.png"
echo Stage 1 done: %JOB%
pause
