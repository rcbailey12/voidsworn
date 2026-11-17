@echo off
rem Refs #975. Station-specific recipe stages 5-7, captures and station-map gate.
setlocal
for %%I in ("%~dp0..\..\..\..") do set "REPO=%%~fI"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "OUT=%VT%\board\issue-975\shots"
set "RAW=%TEMP%\station975_native"
set "GD=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "B=%VT%\blender\blender-4.5.14-windows-x64\blender.exe"
set "PY=%VT%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe"
set "KIT=%~dp0"
set "BASEARG="
if exist "%VT%\board_b\issue-373\shots\review8\station_T2_review.glb" set BASEARG=--baseline "%VT%\board_b\issue-373\shots\review8\station_T2_review.glb"
if not exist "%OUT%" mkdir "%OUT%"
if not exist "%RAW%" mkdir "%RAW%"
if "%STATION_START_STAGE%"=="7" goto :exported
if not "%STATION_START_STAGE%"=="" if not "%STATION_START_STAGE%"=="5" goto :bad
rem Stage 5. Geometry masks and Hegemony stack tiles, never projected concept art.
call "%REPO%\tools\pc\tmo.bat" 21600 "%B%" -b -t 8 --python-exit-code 1 -P "%KIT%production.py" -- --out "%OUT%" --project "%REPO%\godot" > "%TEMP%\station975_bake.log" 2>&1
if errorlevel 1 goto :bad
:exported
rem Stage 6. Full-detail cost and texture density from the actual exported GLB.
"%PY%" "%KIT%production_check.py" "%OUT%" %BASEARG%
if errorlevel 1 goto :bad
rem Stage 7. Copy replaced files aside before installation; never delete.
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%T"
set "OLD=%OUT%\replaced_%STAMP%"
set "ASSET=%REPO%\godot\assets\ships\station_T2"
if not exist "%OLD%" mkdir "%OLD%"
if not exist "%ASSET%" mkdir "%ASSET%"
if exist "%ASSET%\station_T2.glb" copy /y "%ASSET%\station_T2.glb" "%OLD%\" >nul
if exist "%REPO%\godot\gen\ships\station_T2.scn" copy /y "%REPO%\godot\gen\ships\station_T2.scn" "%OLD%\" >nul
copy /y "%OUT%\station_T2.glb" "%ASSET%\station_T2.glb" >nul
if errorlevel 1 goto :bad
call "%REPO%\tools\pc\tmo.bat" 900 "%GD%" --headless --path "%REPO%\godot" --script "%KIT%install.gd" > "%TEMP%\station975_install.log" 2>&1
if errorlevel 1 goto :bad
findstr /c:"T2 INSTALL READBACK PASS" "%TEMP%\station975_install.log" >nul
if errorlevel 1 goto :bad
rem Warm-up once, capture again and keep the second run.
for %%P in (1 2) do (
  call "%REPO%\tools\pc\tmo.bat" 900 "%GD%" --path "%REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script "%KIT%production_capture.gd" -- "%RAW%" "%OUT%" > "%TEMP%\station975_capture%%P.log" 2>&1
  if errorlevel 1 goto :bad
  findstr /c:"SCRIPT ERROR:" /c:"ERROR:" "%TEMP%\station975_capture%%P.log" >nul
  if not errorlevel 1 goto :bad
)
"%PY%" "%KIT%production_pictures.py" "%RAW%" "%OUT%"
if errorlevel 1 goto :bad
rem The real 20-ship battle, on its station map. Timings own the GPU alone.
set "PC_GPU_MODE=solo"
call "%REPO%\tools\pc\tmo.bat" 1800 "%GD%" --path "%REPO%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%OUT%\gate" --map station --modes base,res_2160 --sessions 3 --warmup 120 --frames 720 > "%TEMP%\station975_gate.log" 2>&1
if errorlevel 1 goto :bad
"%PY%" "%KIT%production_check.py" "%OUT%" --gate %BASEARG%
if errorlevel 1 goto :bad
echo station_T2 production route PASS. Review pictures: %OUT%
if not "%RECIPE_NOPAUSE%"=="1" pause
exit /b 0
:bad
echo station_T2 production route FAILED. Read station975 logs in TEMP.
if not "%RECIPE_NOPAUSE%"=="1" pause
exit /b 1
