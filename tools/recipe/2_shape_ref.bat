@echo off
rem Ship recipe, stage 2: the AI shape reference. TRELLIS.2 (free, local, GPU) turns the concept's cut-out into one whole-hull mesh,
rem Downloads\voidsworn_test\bakeoff\SHIP_trellis.glb. It is a shape reference and a source of surface grime only, never shipped.
rem Every current concept already has one (the Nov fleet run); this stage only runs for a new concept. Needs the cut-out
rem Downloads\voidsworn_meshes\picks\SHIP_cut.png (the concept on transparent background). About 2 to 4 minutes on the 5080.
rem Exits non-zero (FAILED) when the shape reference is still missing afterwards.
call "%~dp0env.bat"
if exist "%B0%" (echo Stage 2 done: shape reference already made: %B0% & pause & exit /b 0)
if not exist "%TPY%" (echo Stage 2 FAILED: the TRELLIS.2 venv is not at %TPY% & goto bad)
if not exist "%JOB%\concept.png" (echo Stage 2 FAILED: run stage 1 first, no %JOB%\concept.png & goto bad)
if not exist "%USERPROFILE%\Downloads\voidsworn_meshes\picks\%SHIP%_cut.png" copy /y "%JOB%\concept.png" "%USERPROFILE%\Downloads\voidsworn_meshes\picks\%SHIP%_cut.png" > nul
set TRELLIS_CODES=%SHIP%
"%TPY%" "%REPO%\tools\pc\trellis_fleet.py"
if not exist "%B0%" (echo Stage 2 FAILED: no shape reference written. See Downloads\voidsworn_test\bakeoff\trellis_fleet.log & goto bad)
echo Stage 2 done: %B0%
pause
exit /b 0
:bad
pause
exit /b 1
