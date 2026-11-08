@echo off
rem Issue 207 scene gate benchmark (Opus). Queue job (queue\, runs from build\; nothing in build\ is changed).
rem 1. A fresh clone of branch opus/issue-207 in Downloads\voidsworn_test\opus207\repo (or an update of that clone).
rem 2. The A4 ship files copied in from build\godot\assets\ships (they live only on this PC, out of git by design), so
rem    the clone builds the same ships the game shows. Copy only; nothing is deleted anywhere.
rem 3. Its own Godot import (after the copy, so the ship textures import too) and asset build (hulls, the max-detail
rem    flagships from enginetest\assets\hi, A4 kit ships, sky). The A4 ship files are touched first so every run
rem    rebuilds those ships from the copied files.
rem 4. res://bench/scene_gate.tscn on the RTX 5080: two launches of every mode (3 sessions each), then base against the
rem    3D drawn at 1440p and 4K pixel counts (3 sessions).
rem Output: Downloads\voidsworn_test\opus207\out\ (status.txt, run1\, run2\, run3_res\, logs, GPU state).
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\opus207"
set "R=%W%\repo"
set "O=%W%\out"
set /p G=<"%VT%\godot_path.txt"
if not exist "%O%" mkdir "%O%"
echo v2 start %date% %time% >> "%O%\status.txt"
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
robocopy "%VT%\build\godot\assets\ships" "%R%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NP /NDL /R:1 /W:1 > "%O%\a4copy_log.txt" 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Recurse -File '%R%\godot\assets\ships' -Include *.glb,*.jpg,*.png | Get-FileHash -Algorithm SHA256 | ForEach-Object { $_.Hash.ToLower() + ' ' + (Split-Path $_.Path -Leaf) + ' ' + (Get-Item $_.Path).Length } | Set-Content '%O%\a4copy_sha256.txt'"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Recurse -File '%R%\godot\assets\ships' -Filter *.glb | ForEach-Object { $_.LastWriteTime = Get-Date }"
echo import %time% >> "%O%\status.txt"
call "%TMO%" 2400 "%G%" --headless --path "%R%\godot" --import > "%O%\import_log.txt" 2>&1
echo assets %time% >> "%O%\status.txt"
call "%TMO%" 2400 "%G%" --headless --path "%R%\godot" --script res://render/build_assets.gd -- --repo "%R%" --hi "%VT%\enginetest\assets\hi" --env "%VT%\enginetest\assets\env" > "%O%\build_assets_log.txt" 2>&1
for %%N in (2 3) do if not exist "%R%\godot\gen\v3.txt" call "%TMO%" 2400 "%G%" --headless --path "%R%\godot" --script res://render/build_assets.gd -- --repo "%R%" --hi "%VT%\enginetest\assets\hi" --env "%VT%\enginetest\assets\env" >> "%O%\build_assets_log.txt" 2>&1
if not exist "%R%\godot\gen\v3.txt" echo assets not finished >> "%O%\status.txt"
find /c "Failed loading resource" "%O%\build_assets_log.txt" >> "%O%\status.txt"
copy /y "%R%\godot\gen\manifest.json" "%O%\gen_manifest.json" >nul 2>&1
set "Q=--query-gpu=name,driver_version,utilization.gpu,clocks.gr,clocks.mem,temperature.gpu,power.draw,pstate,memory.used"
nvidia-smi %Q% --format=csv > "%O%\gpu_state.txt" 2>&1
echo bench run1 %time% >> "%O%\status.txt"
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\run1" > "%O%\run1_log.txt" 2>&1
nvidia-smi %Q% --format=csv,noheader >> "%O%\gpu_state.txt" 2>&1
echo bench run2 %time% >> "%O%\status.txt"
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\run2" > "%O%\run2_log.txt" 2>&1
nvidia-smi %Q% --format=csv,noheader >> "%O%\gpu_state.txt" 2>&1
echo bench run3_res %time% >> "%O%\status.txt"
call "%TMO%" 1800 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\run3_res" --modes base,res_1440,res_2160 > "%O%\run3_res_log.txt" 2>&1
nvidia-smi %Q% --format=csv,noheader >> "%O%\gpu_state.txt" 2>&1
nvidia-smi > "%O%\gpu_after.txt" 2>&1
echo done %date% %time% >> "%O%\status.txt"
dir /b /s "%O%" > "%O%\files.txt"
cd /d "%VT%\build"
exit /b 0
