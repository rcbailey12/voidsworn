@echo off
rem Issue 207: a second launch of every mode at the engagement camera (the gate view), for launch-to-launch spread.
rem Runs on the clone bench207_scene_gate.bat made (updated to the branch tip). Output: opus207\out\run4\.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\opus207"
set "R=%W%\repo"
set "O=%W%\out"
set /p G=<"%VT%\godot_path.txt"
if not exist "%R%\.git" (
  echo no clone: run bench207_scene_gate.bat first >> "%O%\status.txt"
  exit /b 1
)
echo repeat start %date% %time% >> "%O%\status.txt"
git -C "%R%" fetch --depth 1 origin opus/issue-207 > "%O%\git_log_repeat.txt" 2>&1
git -C "%R%" reset --hard FETCH_HEAD >> "%O%\git_log_repeat.txt" 2>&1
git -C "%R%" log -1 --format=%%H > "%O%\commit_repeat.txt" 2>&1
set "TMO=%R%\tools\pc\tmo.bat"
set "Q=--query-gpu=name,driver_version,utilization.gpu,clocks.gr,clocks.mem,temperature.gpu,power.draw,pstate,memory.used"
nvidia-smi %Q% --format=csv,noheader >> "%O%\gpu_state.txt" 2>&1
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\run4" > "%O%\run4_log.txt" 2>&1
nvidia-smi %Q% --format=csv,noheader >> "%O%\gpu_state.txt" 2>&1
nvidia-smi > "%O%\gpu_after_repeat.txt" 2>&1
echo repeat done %date% %time% >> "%O%\status.txt"
dir /b /s "%O%" > "%O%\files.txt"
cd /d "%VT%\build"
exit /b 0
