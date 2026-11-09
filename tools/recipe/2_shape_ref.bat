@echo off
rem Ship recipe, stage 2: the AI shape reference. TRELLIS.2 (free, local, GPU) turns the concept's cut-out into one whole-hull mesh,
rem Downloads\voidsworn_test\bakeoff\SHIP_trellis.glb. It is a shape reference and a source of surface grime only, never shipped.
rem Every current concept already has one (the Nov fleet run); this stage only runs for a new concept. Needs the cut-out
rem Downloads\voidsworn_meshes\picks\SHIP_cut.png (the concept on transparent background). About 2 to 4 minutes on the 5080.
call "%~dp0env.bat"
if exist "%B0%" (echo Shape reference already made: %B0% & pause & exit /b 0)
if not exist "%USERPROFILE%\Downloads\voidsworn_meshes\picks\%SHIP%_cut.png" copy /y "%JOB%\concept.png" "%USERPROFILE%\Downloads\voidsworn_meshes\picks\%SHIP%_cut.png" > nul
set TRELLIS_CODES=%SHIP%
"%TPY%" "%REPO%\tools\pc\trellis_fleet.py"
if exist "%B0%" (echo Stage 2 done: %B0%) else (echo Stage 2 FAILED: see Downloads\voidsworn_test\bakeoff\trellis_fleet.log)
pause
