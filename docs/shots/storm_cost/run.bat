@echo off
rem Issue 982. Run before editing world_living.gd, then run after the change.
rem Requires the installed gen cache and its ship textures, already imported.
setlocal
for %%R in ("%~dp0..\..\..") do set "R=%%~fR"
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "G=%V%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "S=%V%\board\issue-982\shots"
set "D=%R%\docs\shots\storm_cost"
set "TAG=%~1"
if not defined TAG set "TAG=after"
if not "%TAG%"=="before" if not "%TAG%"=="after" exit /b 2
set "O=%TEMP%\982_%TAG%"
if not exist "%O%" mkdir "%O%"
set "PC_GPU_ISSUE=982"
set "PC_GPU_MODE=solo"
set "PICTURE_SOURCE_REPO=%R%"
cd /d "%R%"
nvidia-smi --query-gpu=name,driver_version,utilization.gpu,clocks.gr,clocks.mem,temperature.gpu,power.draw,pstate,memory.used --format=csv > "%O%\gpu.csv"
call "%R%\tools\pc\tmo.bat" 1200 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script ../docs/shots/storm_cost/measure.gd -- "%O%\storm" timing > "%O%\storm.log" 2>&1
if errorlevel 1 exit /b 1
copy /y "%O%\storm\results.json" "%D%\%TAG%_storm.json" >nul
call "%R%\tools\pc\tmo.bat" 600 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script ../docs/shots/storm_cost/measure.gd -- "%S%\%TAG%" shots > "%O%\shots.log" 2>&1
if errorlevel 1 exit /b 1
for %%P in (warm keep) do (
  call "%R%\tools\pc\tmo.bat" 1200 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\gate_%%P" --sessions 3 --warmup 180 --frames 720 --modes base,res_2160 > "%O%\gate_%%P.log" 2>&1
  if errorlevel 1 exit /b 1
  copy /y "%O%\gate_%%P\scene_gate.json" "%D%\%TAG%_gate_%%P.json" >nul
)
nvidia-smi --query-gpu=name,driver_version,utilization.gpu,clocks.gr,clocks.mem,temperature.gpu,power.draw,pstate,memory.used --format=csv,noheader >> "%O%\gpu.csv"
copy /y "%O%\gpu.csv" "%D%\%TAG%_gpu.csv" >nul
echo Issue 982 %TAG% finished. Logs: %O%
exit /b 0
