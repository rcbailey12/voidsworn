@echo off
rem Issue 207 scene gate benchmark (Opus). Queue job (queue\, runs from build\; nothing in build\ is touched).
rem 1. A fresh clone of branch opus/issue-207 in Downloads\voidsworn_test\opus207\repo (or an update of that clone).
rem 2. Its own Godot import and asset build (hulls, the max-detail flagships from enginetest\assets\hi, A4 kit ships, sky).
rem 3. Two launches of res://bench/scene_gate.tscn (3 sessions each, every mode) on the RTX 5080 at 1920x1080.
rem Output: Downloads\voidsworn_test\opus207\out\ (status.txt, run1\, run2\, logs, GPU state before and after).
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\opus207"
set "R=%W%\repo"
set "O=%W%\out"
set /p G=<"%VT%\godot_path.txt"
if not exist "%O%" mkdir "%O%"
echo start %date% %time% > "%O%\status.txt"
if exist "%R%\.git" goto update
git clone --depth 1 --branch opus/issue-207 https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git_log.txt" 2>&1
goto cloned
:update
git -C "%R%" fetch --depth 1 origin opus/issue-207 > "%O%\git_log.txt" 2>&1
git -C "%R%" reset --hard FETCH_HEAD >> "%O%\git_log.txt" 2>&1
:cloned
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt" 2>&1
if not exist "%R%\godot\bench\scene_gate.tscn" (
  echo clone failed >> "%O%\status.txt"
  exit /b 1
)
set "TMO=%R%\tools\pc\tmo.bat"
nvidia-smi > "%O%\gpu_before.txt" 2>&1
echo import %time% >> "%O%\status.txt"
if not exist "%R%\godot\.godot\imported" call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\import_log.txt" 2>&1
echo assets %time% >> "%O%\status.txt"
for %%N in (1 2 3) do if not exist "%R%\godot\gen\v3.txt" call "%TMO%" 2400 "%G%" --headless --path "%R%\godot" --script res://render/build_assets.gd -- --repo "%R%" --hi "%VT%\enginetest\assets\hi" --env "%VT%\enginetest\assets\env" >> "%O%\build_assets_log.txt" 2>&1
if not exist "%R%\godot\gen\v3.txt" echo assets not finished >> "%O%\status.txt"
copy /y "%R%\godot\gen\manifest.json" "%O%\gen_manifest.json" >nul 2>&1
set "Q=--query-gpu=name,driver_version,utilization.gpu,clocks.gr,clocks.mem,temperature.gpu,power.draw,pstate,memory.used"
nvidia-smi %Q% --format=csv > "%O%\gpu_state.txt" 2>&1
echo bench run1 %time% >> "%O%\status.txt"
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\run1" > "%O%\run1_log.txt" 2>&1
nvidia-smi %Q% --format=csv,noheader >> "%O%\gpu_state.txt" 2>&1
echo bench run2 %time% >> "%O%\status.txt"
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\run2" > "%O%\run2_log.txt" 2>&1
nvidia-smi %Q% --format=csv,noheader >> "%O%\gpu_state.txt" 2>&1
nvidia-smi > "%O%\gpu_after.txt" 2>&1
echo done %date% %time% >> "%O%\status.txt"
dir /b /s "%O%" > "%O%\files.txt"
cd /d "%VT%\build"
exit /b 0
