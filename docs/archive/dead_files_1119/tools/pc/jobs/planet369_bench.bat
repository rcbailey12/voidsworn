@echo off
setlocal
set "V369=%USERPROFILE%\Downloads\voidsworn_test"
set "R369=%~dp0..\..\.."
set "O369=%V369%\board\issue-369\shots"
set "G369=%V369%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "T369=%~dp0..\tmo.bat"
rem Run 2: the Board's standing GPU clearance is the first line of gpu_go.txt.
if not exist "%V369%\gpu_go.txt" exit /b 2
set "GPU369="
set /p "GPU369="<"%V369%\gpu_go.txt"
if not "%GPU369:~0,11%"=="GPU cleared" exit /b 2
rem Copy only, before import. Never mirror, purge, remove or overwrite tracked manifests.
if not exist "%V369%\build\godot\gen\manifest.json" exit /b 2
robocopy "%V369%\build\godot\gen" "%R369%\godot\gen" /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 >nul
if errorlevel 8 exit /b 2
robocopy "%V369%\build\godot\assets\ships" "%R369%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NJS /NP /R:1 /W:1 >nul
if errorlevel 8 exit /b 2
if not exist "%O369%" mkdir "%O369%"
call "%T369%" 1200 "%G369%" --headless --log-file "%TEMP%\planet369_import_engine.log" --path "%R369%\godot" --import > "%TEMP%\planet369_import.log" 2>&1
if errorlevel 1 exit /b 1
rem Surface-only repeats are for a material correction after a completed gate.
if /i "%~1"=="surface_after" (
  call :probe after
  exit /b
)
if /i "%~1"=="surface" (
  call :probe before
  if errorlevel 1 exit /b 1
  call :probe after
  exit /b
)
rem "resume" keeps a completed before bench if a later stage needs a retry.
if /i "%~1"=="resume" (
  call :sector before
  if errorlevel 1 exit /b 1
) else (
  call :capture before
  if errorlevel 1 exit /b 1
)
call :capture after
if errorlevel 1 exit /b 1
set "VS_PLANET_REMIX=1"
call "%T369%" 300 "%G369%" --log-file "%TEMP%\planet369_showcase_engine.log" --path "%R369%\godot" --resolution 1280x720 --disable-vsync --script "%~dp0planet369_showcase.gd" -- --out "%O369%\showcase" > "%TEMP%\planet369_showcase.log" 2>&1
if errorlevel 1 exit /b 1
exit /b 0
:capture
call :probe %1
if errorlevel 1 exit /b 1
rem The fixed #207 gate also sees the scans. Surface-only changes do not alter it.
call "%T369%" 600 "%G369%" --log-file "%TEMP%\planet369_gate_%1_engine.log" --path "%R369%\godot" --resolution 1920x1080 --disable-vsync res://bench/scene_gate.tscn -- --out "%O369%\%1\gate" --modes base,res_2160 --sessions 3 > "%TEMP%\planet369_gate_%1.log" 2>&1
if errorlevel 1 exit /b 1
call :sector %1
exit /b %ERRORLEVEL%
:probe
set "VS_PLANET_REMIX=1"
if "%1"=="before" set "VS_PLANET_REMIX=0"
set "VS_WORLD_CACHE=%TEMP%\planet369_world_%1_%RANDOM%"
for %%K in (1 2) do (
  nvidia-smi > "%O369%\gpu_%1_%%K.txt"
  call "%T369%" 300 "%G369%" --log-file "%TEMP%\planet369_%1_%%K_engine.log" --path "%R369%\godot" --resolution 1920x1080 --disable-vsync --script "%~dp0planet369_probe.gd" -- --out "%O369%\%1\run%%K" > "%TEMP%\planet369_%1_%%K.log" 2>&1
  if errorlevel 1 exit /b 1
)
rem Keep run2; run1 pays shader warm-up.
exit /b 0
:sector
set "VS_PLANET_REMIX=1"
if "%1"=="before" set "VS_PLANET_REMIX=0"
call "%T369%" 300 "%G369%" --log-file "%TEMP%\planet369_sector_%1_engine.log" --path "%R369%\godot" --resolution 1280x720 res://scenes/campaign/campaign.tscn -- mapshots "%O369%\%1\sector" > "%TEMP%\planet369_sector_%1.log" 2>&1
exit /b %ERRORLEVEL%
