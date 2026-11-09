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
for /f "usebackq delims=" %%L in (`"%BPY%" "%RC%\ship.py" %SHIP% get hull`) do set HULL=%%L
for /f "usebackq delims=" %%L in (`"%BPY%" "%RC%\ship.py" %SHIP% get cell`) do set CELL=%%L
set R209_SHIP=%RC%\ships\%SHIP%.json
set R209_TUNE_JSON=
for /f "usebackq delims=" %%L in (`"%BPY%" "%RC%\ship.py" %SHIP% get tune`) do set R209_TUNE_JSON=%REPO%\%%L
if "%R209_TUNE_JSON%"=="" if exist "%JOB%\tune.json" set R209_TUNE_JSON=%JOB%\tune.json
