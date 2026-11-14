@echo off
rem T2 build sheet, CPU only. No installation or live swap. Refs #373.
setlocal
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "OUT=%VT%\board\issue-373\shots\review3"
set "B=%VT%\blender\blender-4.5.14-windows-x64\blender.exe"
set "GD=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "KIT=%REPO%\tools\blender\kits\hegemony_station"
if not exist "%B%" exit /b 1
if not exist "%GD%" exit /b 1
if not exist "%OUT%" mkdir "%OUT%"
call "%REPO%\tools\pc\tmo.bat" 300 "%GD%" --headless --log-file "%TEMP%\station373_engine.log" --path "%REPO%\godot" --script "%KIT%\inspect.gd" -- "%OUT%\game_inputs.json"
if errorlevel 1 goto :failed
call "%REPO%\tools\pc\tmo.bat" 1200 "%B%" -b -t 8 --python-exit-code 1 -P "%KIT%\review.py" -- --out "%OUT%"
if errorlevel 1 goto :failed
"%VT%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe" "%KIT%\check.py" "%OUT%"
if errorlevel 1 goto :failed
"%VT%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe" "%KIT%\sheets.py" "%OUT%"
if errorlevel 1 goto :failed
echo T2 review sheet written to %OUT%. Board review is next. Nothing installed.
if not "%RECIPE_NOPAUSE%"=="1" pause
exit /b 0
:failed
echo T2 review FAILED. Read the named command above. Nothing installed.
if not "%RECIPE_NOPAUSE%"=="1" pause
exit /b 1
