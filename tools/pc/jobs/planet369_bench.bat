@echo off
setlocal
set "V369=%USERPROFILE%\Downloads\voidsworn_test"
set "R369=%~dp0..\..\.."
set "O369=%V369%\board\issue-369\shots"
set "G369=%V369%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "T369=%~dp0..\tmo.bat"
rem The Board writes go.txt only after Ryan frees the GPU. No other go file counts.
:wait
if exist "%V369%\board\issue-369\go.txt" goto ready
echo Waiting for the issue-369 GPU go file.
timeout /t 10 /nobreak >nul
goto wait
:ready
rem Copy only, before import. Never mirror, purge, remove or overwrite tracked manifests.
if not exist "%V369%\build\godot\gen\manifest.json" exit /b 2
robocopy "%V369%\build\godot\gen" "%R369%\godot\gen" /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 >nul
if errorlevel 8 exit /b 2
robocopy "%V369%\build\godot\assets\ships" "%R369%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NJS /NP /R:1 /W:1 >nul
if errorlevel 8 exit /b 2
if not exist "%O369%" mkdir "%O369%"
call "%T369%" 1200 "%G369%" --headless --log-file "%TEMP%\planet369_import_engine.log" --path "%R369%\godot" --import > "%TEMP%\planet369_import.log" 2>&1
if errorlevel 1 exit /b 1
for %%M in (before after) do (
  call :capture %%M
  if errorlevel 1 exit /b 1
)
exit /b 0
:capture
set "VS_PLANET_REMIX=1"
if "%1"=="before" set "VS_PLANET_REMIX=0"
set "VS_WORLD_CACHE=%TEMP%\planet369_world_%1_%RANDOM%"
for %%K in (1 2) do (
  nvidia-smi > "%O369%\gpu_%1_%%K.txt"
  call "%T369%" 300 "%G369%" --log-file "%TEMP%\planet369_%1_%%K_engine.log" --path "%R369%\godot" --resolution 1920x1080 --fixed-fps 60 --disable-vsync --script "%~dp0planet369_probe.gd" -- --out "%O369%\%1\run%%K" > "%TEMP%\planet369_%1_%%K.log" 2>&1
  if errorlevel 1 exit /b 1
)
rem Keep run2; run1 pays shader warm-up. The fixed #207 gate also sees the scans.
call "%T369%" 600 "%G369%" --log-file "%TEMP%\planet369_gate_%1_engine.log" --path "%R369%\godot" --resolution 1920x1080 --disable-vsync res://bench/scene_gate.tscn -- --out "%O369%\%1\gate" --modes base,res_2160 --sessions 3 > "%TEMP%\planet369_gate_%1.log" 2>&1
if errorlevel 1 exit /b 1
call "%T369%" 300 "%G369%" --log-file "%TEMP%\planet369_sector_%1_engine.log" --path "%R369%\godot" --resolution 1280x720 res://scenes/campaign/campaign_scene.tscn -- mapshots "%O369%\%1\sector" > "%TEMP%\planet369_sector_%1.log" 2>&1
exit /b %ERRORLEVEL%
