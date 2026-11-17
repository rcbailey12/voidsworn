@echo off
rem Refs #863. Add debris to the already painted T2, preserving its base cache.
setlocal
for %%I in ("%~dp0..\..\..\..") do set "REPO=%%~fI"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "OUT=%VT%\board\issue-863\shots"
set "RAW=%TEMP%\station863_native"
set "GD=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "BL=%VT%\blender\blender-4.5.14-windows-x64\blender.exe"
set "PY=%VT%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe"
set "KIT=%~dp0"
set "PICTURE_SOURCE_REPO=%REPO%"
if not exist "%OUT%" mkdir "%OUT%"
if not exist "%RAW%" mkdir "%RAW%"
if not exist "%REPO%\godot\gen\ships\station_T2.scn" goto :bad
if "%STATION_DEBRIS_RESUME%"=="1" goto :install
call "%REPO%\tools\pc\tmo.bat" 900 "%BL%" -b -t 8 --python-exit-code 1 -P "%KIT%debris.py" -- --out "%OUT%" --station "%REPO%\godot\assets\ships\station_T2\station_T2.glb" > "%TEMP%\station863_build.log" 2>&1
if errorlevel 1 goto :bad
:install
call "%REPO%\tools\pc\tmo.bat" 900 "%GD%" --headless --path "%REPO%\godot" --script "%KIT%debris_install.gd" -- "%OUT%\station_T2_debris.glb" > "%TEMP%\station863_install.log" 2>&1
if errorlevel 1 goto :bad
call "%REPO%\tools\pc\tmo.bat" 900 "%GD%" --headless --path "%REPO%\godot" --script "%KIT%debris_check.gd" -- "%OUT%\debris_checks.json" > "%TEMP%\station863_check.log" 2>&1
if errorlevel 1 goto :bad
for %%P in (1 2) do (
  call "%REPO%\tools\pc\tmo.bat" 900 "%GD%" --path "%REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script "%KIT%debris_capture.gd" -- "%RAW%" > "%TEMP%\station863_capture%%P.log" 2>&1
  if errorlevel 1 goto :bad
  findstr /c:"SCRIPT ERROR:" /c:"ERROR:" "%TEMP%\station863_capture%%P.log" >nul
  if not errorlevel 1 goto :bad
)
"%PY%" "%KIT%debris_pictures.py" "%RAW%" "%OUT%"
if errorlevel 1 goto :bad
copy /y "%RAW%\debris_captures.json" "%OUT%\debris_captures.json" >nul
echo station_T2 debris route PASS. Pictures and clearance report: %OUT%
if not "%RECIPE_NOPAUSE%"=="1" pause
exit /b 0
:bad
echo station_T2 debris route FAILED. Read station863 logs in TEMP.
if not "%RECIPE_NOPAUSE%"=="1" pause
exit /b 1
