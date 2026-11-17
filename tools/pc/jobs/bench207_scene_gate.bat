@echo off
rem Issue 207 scene gate benchmark (Opus). Queue job (queue\, runs from build\; nothing in build\ is changed).
rem 1. A fresh clone of branch opus/issue-207 in Downloads\voidsworn_test\opus207\repo (or an update of that clone).
rem 2. The A4 ship files copied in from build\godot\assets\ships (they live only on this PC, out of git by design), so
rem    the clone builds the same ships the game shows. Copy only; nothing is deleted anywhere.
rem 3. Its own Godot import (after the copy, so the ship textures import too) and asset build (hulls, the max-detail
rem    flagships from the hi folder, A4 kit ships, sky). The A4 ship files are touched first so every run
rem    rebuilds those ships from the copied files.
rem 4. res://bench/scene_gate.tscn on the RTX 5080: two launches of every mode (3 sessions each), then base against the
rem    3D drawn at 1440p and 4K pixel counts (3 sessions).
rem Output: Downloads\voidsworn_test\opus207\out\ (status.txt, run1\, run2\, run3_res\, logs, GPU state).
rem Issue 873: every import, build_assets pass and bench run is checked. A failed step prints FAILED with its name,
rem appends the same line to out\status.txt and exits non-zero. The job no longer ends with exit /b 0 regardless.
rem Issue 873: the hi and env folders are not guessed. %VT%\bench207_settings.txt holds two lines:
rem   hi=<folder with the 8K flagship glb files>
rem   env=<folder with sky_deadstar_8k.png>
rem A missing settings file, a missing key or a missing folder is a clear FAILED before the clone (no silent fallback).
rem Issue 952: keep old output folders. Before each bench, refresh a marker and require scene_gate.json to be newer.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\opus207"
set "R=%W%\repo"
set "O=%W%\out"
set "G="
if exist "%VT%\godot_path.txt" set /p G=<"%VT%\godot_path.txt"
if not exist "%O%" mkdir "%O%"
echo v2 start %date% %time% >> "%O%\status.txt"
if not defined G (set "FAILMSG=no godot_path.txt at %VT%\godot_path.txt" & goto fail)
set "SETF=%VT%\bench207_settings.txt"
set "HI="
set "ENVF="
if exist "%SETF%" for /f "usebackq tokens=1,* delims==" %%A in ("%SETF%") do (
  if /i "%%A"=="hi" set "HI=%%B"
  if /i "%%A"=="env" set "ENVF=%%B"
)
if not defined HI (set "FAILMSG=no hi folder in %SETF% (add a hi= line)" & goto fail)
if not defined ENVF (set "FAILMSG=no env folder in %SETF% (add an env= line)" & goto fail)
if not exist "%HI%" (set "FAILMSG=the hi folder does not exist: %HI% (from %SETF%)" & goto fail)
if not exist "%ENVF%" (set "FAILMSG=the env folder does not exist: %ENVF% (from %SETF%)" & goto fail)
if exist "%R%\.git" goto update
git clone --depth 1 --branch opus/issue-207 https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=git clone failed; see %O%\git_log.txt" & goto fail)
goto cloned
:update
git -C "%R%" fetch --depth 1 origin opus/issue-207 > "%O%\git_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=git fetch opus/issue-207 failed; see %O%\git_log.txt" & goto fail)
git -C "%R%" reset --hard FETCH_HEAD >> "%O%\git_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=git reset to FETCH_HEAD failed; see %O%\git_log.txt" & goto fail)
:cloned
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt" 2>&1
if not exist "%R%\godot\bench\scene_gate.tscn" (set "FAILMSG=clone has no godot\bench\scene_gate.tscn; see %O%\git_log.txt" & goto fail)
rem Use the installed watchdog, never the old checkout being measured.
set "TMO=%~dp0..\tmo.bat"
nvidia-smi > "%O%\gpu_before.txt" 2>&1
robocopy "%VT%\build\godot\assets\ships" "%R%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NP /NDL /R:1 /W:1 > "%O%\a4copy_log.txt" 2>&1
if errorlevel 8 (set "FAILMSG=the A4 ship copy failed (robocopy code %ERRORLEVEL%); see %O%\a4copy_log.txt" & goto fail)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Recurse -File '%R%\godot\assets\ships' -Include *.glb,*.jpg,*.png | Get-FileHash -Algorithm SHA256 | ForEach-Object { $_.Hash.ToLower() + ' ' + (Split-Path $_.Path -Leaf) + ' ' + (Get-Item $_.Path).Length } | Set-Content '%O%\a4copy_sha256.txt'"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Recurse -File '%R%\godot\assets\ships' -Filter *.glb | ForEach-Object { $_.LastWriteTime = Get-Date }"
echo import %time% >> "%O%\status.txt"
call "%TMO%" 2400 "%G%" --headless --path "%R%\godot" --import > "%O%\import_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=the Godot import failed; see %O%\import_log.txt" & goto fail)
echo assets %time% >> "%O%\status.txt"
call "%TMO%" 2400 "%G%" --headless --path "%R%\godot" --script res://render/build_assets.gd -- --repo "%R%" --hi "%HI%" --env "%ENVF%" > "%O%\build_assets_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=build_assets pass 1 failed; see %O%\build_assets_log.txt" & goto fail)
if exist "%R%\godot\gen\v3.txt" goto assets_done
call "%TMO%" 2400 "%G%" --headless --path "%R%\godot" --script res://render/build_assets.gd -- --repo "%R%" --hi "%HI%" --env "%ENVF%" >> "%O%\build_assets_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=build_assets pass 2 failed; see %O%\build_assets_log.txt" & goto fail)
if exist "%R%\godot\gen\v3.txt" goto assets_done
call "%TMO%" 2400 "%G%" --headless --path "%R%\godot" --script res://render/build_assets.gd -- --repo "%R%" --hi "%HI%" --env "%ENVF%" >> "%O%\build_assets_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=build_assets pass 3 failed; see %O%\build_assets_log.txt" & goto fail)
if exist "%R%\godot\gen\v3.txt" goto assets_done
set "FAILMSG=build_assets wrote no godot\gen\v3.txt after 3 passes; see %O%\build_assets_log.txt" & goto fail
:assets_done
find /c "Failed loading resource" "%O%\build_assets_log.txt" >> "%O%\status.txt"
copy /y "%R%\godot\gen\manifest.json" "%O%\gen_manifest.json" >nul 2>&1
set "Q=--query-gpu=name,driver_version,utilization.gpu,clocks.gr,clocks.mem,temperature.gpu,power.draw,pstate,memory.used"
nvidia-smi %Q% --format=csv > "%O%\gpu_state.txt" 2>&1
echo bench run1 %time% >> "%O%\status.txt"
call :bench_start run1
if errorlevel 1 goto fail
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\run1" > "%O%\run1_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=bench run1 failed; see %O%\run1_log.txt" & goto fail)
call :bench_report run1
if errorlevel 1 goto fail
nvidia-smi %Q% --format=csv,noheader >> "%O%\gpu_state.txt" 2>&1
echo bench run2 %time% >> "%O%\status.txt"
call :bench_start run2
if errorlevel 1 goto fail
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\run2" > "%O%\run2_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=bench run2 failed; see %O%\run2_log.txt" & goto fail)
call :bench_report run2
if errorlevel 1 goto fail
nvidia-smi %Q% --format=csv,noheader >> "%O%\gpu_state.txt" 2>&1
echo bench run3_res %time% >> "%O%\status.txt"
call :bench_start run3_res
if errorlevel 1 goto fail
call "%TMO%" 1800 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\run3_res" --modes base,res_1440,res_2160 > "%O%\run3_res_log.txt" 2>&1
if errorlevel 1 (set "FAILMSG=bench run3_res failed; see %O%\run3_res_log.txt" & goto fail)
call :bench_report run3_res
if errorlevel 1 goto fail
nvidia-smi %Q% --format=csv,noheader >> "%O%\gpu_state.txt" 2>&1
nvidia-smi > "%O%\gpu_after.txt" 2>&1
echo done %date% %time% >> "%O%\status.txt"
dir /b /s "%O%" > "%O%\files.txt"
cd /d "%VT%\build"
exit /b 0
:bench_start
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Set-Content -LiteralPath (Join-Path $env:O '%~1_started.txt') -Value 'bench %~1 started'"
if errorlevel 1 (set "FAILMSG=bench %~1 could not write its fresh run marker at %O%\%~1_started.txt" & exit /b 1)
exit /b 0
:bench_report
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $marker=Get-Item -LiteralPath (Join-Path $env:O '%~1_started.txt'); $report=Get-Item -LiteralPath (Join-Path $env:O '%~1\scene_gate.json'); if ($report.PSIsContainer -or $report.LastWriteTimeUtc -le $marker.LastWriteTimeUtc) { exit 1 }"
if errorlevel 1 (set "FAILMSG=bench %~1 wrote no fresh scene_gate.json at %O%\%~1; report must be newer than %~1_started.txt; see %O%\%~1_log.txt" & exit /b 1)
exit /b 0
:fail
echo FAILED: %FAILMSG%
echo FAILED: %FAILMSG% >> "%O%\status.txt"
cd /d "%VT%\build" 2>nul
exit /b 1
