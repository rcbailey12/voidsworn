@echo off
rem Issue 207, part 2: the same scene with the 3D drawn at 2560x1440 and 3840x2160 pixel counts (Ryan's 1440p and 4K
rem screens), paired with base, 3 sessions. Runs after bench207_scene_gate.bat on its clone (updated to the branch tip).
rem Output: Downloads\voidsworn_test\opus207\out\run3_res\ and run3_res_log.txt.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\opus207"
set "R=%W%\repo"
set "O=%W%\out"
set /p G=<"%VT%\godot_path.txt"
if not exist "%O%" mkdir "%O%"
if not exist "%R%\.git" (
  echo no clone: run bench207_scene_gate.bat first >> "%O%\status.txt"
  exit /b 1
)
echo res start %date% %time% >> "%O%\status.txt"
git -C "%R%" fetch --depth 1 origin opus/issue-207 > "%O%\git_log_res.txt" 2>&1
git -C "%R%" reset --hard FETCH_HEAD >> "%O%\git_log_res.txt" 2>&1
git -C "%R%" log -1 --format=%%H > "%O%\commit_res.txt" 2>&1
set "TMO=%R%\tools\pc\tmo.bat"
set "Q=--query-gpu=name,driver_version,utilization.gpu,clocks.gr,clocks.mem,temperature.gpu,power.draw,pstate,memory.used"
nvidia-smi %Q% --format=csv,noheader >> "%O%\gpu_state.txt" 2>&1
call "%TMO%" 1800 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\run3_res" --modes base,res_1440,res_2160 > "%O%\run3_res_log.txt" 2>&1
nvidia-smi %Q% --format=csv,noheader >> "%O%\gpu_state.txt" 2>&1
echo res done %date% %time% >> "%O%\status.txt"
dir /b /s "%O%" > "%O%\files.txt"
cd /d "%VT%\build"
exit /b 0
