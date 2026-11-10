@echo off
rem Ship recipe: shared settings for every stage (called by the stage .bat files, not run on its own).
rem Asks for the ship id once (the concept file name without .webp, for example C15s_23); Enter keeps C15s_23.
set V=%USERPROFILE%\Downloads\voidsworn_test
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set BPY=%V%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set TPY=%USERPROFILE%\Downloads\trellis2\code\venv\Scripts\python.exe
for %%I in ("%~dp0..\..") do set REPO=%%~fI
set R=%REPO%\tools\blender\r209
set RC=%REPO%\tools\recipe
if "%SHIP%"=="" set /p SHIP=Ship id (Enter for C15s_23): 
if "%SHIP%"=="" set SHIP=C15s_23
set JOB=%V%\recipe\%SHIP%
set B0=%V%\bakeoff\%SHIP%_trellis.glb
if not exist "%JOB%" mkdir "%JOB%"
rem Pillow and scipy in Blender's own python, before any stage uses it (stage 1's concept write needs Pillow). First run only.
"%BPY%" -c "import scipy, PIL" 2> nul || ("%BPY%" -m ensurepip & "%BPY%" -m pip install scipy pillow)
"%BPY%" -c "import scipy, PIL" 2> nul || echo WARNING: Pillow or scipy is still missing from Blender's python; stages 1, 3 and 4 will stop.
for /f "usebackq delims=" %%L in (`"%BPY%" "%RC%\ship.py" %SHIP% get hull`) do set HULL=%%L
for /f "usebackq delims=" %%L in (`"%BPY%" "%RC%\ship.py" %SHIP% get cell`) do set CELL=%%L
rem round 7: the bake builds with the ship's own hull module (bakeAb6.py reads R209_HULL); CODE is the ship folder's name in the game
set R209_HULL=%HULL%
set CODE=
for /f "usebackq delims=" %%L in (`"%BPY%" "%RC%\ship.py" %SHIP% get game_code`) do set CODE=%%L
if "%CODE%"=="" set CODE=%SHIP%
set R209_SHIP=%RC%\ships\%SHIP%.json
set R209_TUNE_JSON=
for /f "usebackq delims=" %%L in (`"%BPY%" "%RC%\ship.py" %SHIP% get tune`) do set R209_TUNE_JSON=%REPO%\%%L
if "%R209_TUNE_JSON%"=="" if exist "%JOB%\tune.json" set R209_TUNE_JSON=%JOB%\tune.json
rem the stage 5 bake script, chosen by the ship json ("bake"); bakeAb6.py builds whichever hull module HULL names, so it serves any
rem ship whose hull module follows armA5 to armA7; a ship with its own bake names it in its json
set BAKE=
for /f "usebackq delims=" %%L in (`"%BPY%" "%RC%\ship.py" %SHIP% get bake`) do set BAKE=%%L
if "%BAKE%"=="" set BAKE=bakeAb6.py
