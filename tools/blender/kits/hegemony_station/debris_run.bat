@echo off
rem Refs #863. Build, check and capture the approved painted T2 with detached debris.
setlocal
for %%I in ("%~dp0..\..\..\..") do set "REPO=%%~fI"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "OUT=%VT%\board\issue-863\shots"
set "WORK=%TEMP%\station863_run2"
set "RUN=%WORK%\run_%RANDOM%_%RANDOM%"
set "RAW=%RUN%\native"
set "GD=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "BL=%VT%\blender\blender-4.5.14-windows-x64\blender.exe"
set "PY=%VT%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe"
set "APPROVED=%VT%\board\issue-975\shots\production_checks.json"
set "KIT=%~dp0"
set "PICTURE_SOURCE_REPO=%REPO%"
set "TMO_REPO="
set "TMO_OUT="
set "TMO_LOG="
set "TMO_ERR_LOG="
if not exist "%OUT%" mkdir "%OUT%"
if not exist "%RAW%" mkdir "%RAW%"
if not exist "%APPROVED%" goto :bad
if not exist "%REPO%\godot\gen\ships\station_T2.scn" goto :bad
if "%STATION_DEBRIS_RESUME%"=="1" goto :install
call "%REPO%\tools\pc\tmo.bat" 900 "%BL%" -b -t 8 --python-exit-code 1 -P "%KIT%debris.py" -- --out "%WORK%" --station "%REPO%\godot\assets\ships\station_T2\station_T2.glb" > "%RUN%\build.log" 2>&1
if errorlevel 1 goto :bad
:install
copy /y "%WORK%\station_T2_debris.glb" "%RUN%\" >nul
if errorlevel 1 goto :bad
copy /y "%WORK%\debris_manifest.json" "%RUN%\" >nul
if errorlevel 1 goto :bad
call "%REPO%\tools\pc\tmo.bat" 900 "%GD%" --headless --path "%REPO%\godot" --script "%KIT%debris_install.gd" -- "%RUN%\station_T2_debris.glb" > "%RUN%\install.log" 2>&1
if errorlevel 1 goto :bad
findstr /c:"T2 DEBRIS CACHE INSTALLED" "%RUN%\install.log" >nul
if errorlevel 1 goto :bad
call "%REPO%\tools\pc\tmo.bat" 900 "%GD%" --headless --path "%REPO%\godot" --script "%KIT%debris_check.gd" -- "%RUN%\debris_checks.json" > "%RUN%\check.log" 2>&1
if errorlevel 1 goto :bad
if not defined STATION_DEBRIS_RULES goto :capture
call "%REPO%\tools\pc\tmo.bat" 900 "%GD%" --headless --path "%REPO%\godot" --script "%KIT%debris_check.gd" -- "%RUN%\debris_checks_983.json" "%STATION_DEBRIS_RULES%" > "%RUN%\check_983.log" 2>&1
if errorlevel 1 goto :bad
:capture
for %%P in (1 2) do (
  call "%REPO%\tools\pc\tmo.bat" 900 "%GD%" --path "%REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script "%KIT%debris_capture.gd" -- "%RAW%" > "%RUN%\capture%%P.log" 2>&1
  if errorlevel 1 goto :bad
  findstr /c:"SCRIPT ERROR:" /c:"ERROR:" "%RUN%\capture%%P.log" >nul
  if not errorlevel 1 goto :bad
)
set "PC_GPU_MODE=solo"
call "%REPO%\tools\pc\tmo.bat" 1800 "%GD%" --path "%REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%RUN%\gate" --map station --modes base,res_2160 --sessions 3 --warmup 120 --frames 720 > "%RUN%\gate.log" 2>&1
if errorlevel 1 goto :bad
"%PY%" "%KIT%debris_pictures.py" "%RAW%" "%RUN%" "%OUT%" "%APPROVED%" --gate "%RUN%\gate\scene_gate.json"
if errorlevel 1 goto :bad
echo station_T2 debris route PASS. Pictures: %OUT%
echo Check data and logs: %RUN%
if not "%RECIPE_NOPAUSE%"=="1" pause
exit /b 0
:bad
echo station_T2 debris route FAILED. Read logs in %RUN%.
if not "%RECIPE_NOPAUSE%"=="1" pause
exit /b 1
