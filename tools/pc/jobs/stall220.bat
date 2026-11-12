@echo off
rem Issue 220: effects spawn stalls (Opus). Queue job (queue\, runs from build\; nothing in build\ is changed).
rem Uses Opus's own clone from #207 (Downloads\voidsworn_test\opus207\repo, the A4 ship files already copied in;
rem untracked, so the branch update keeps them), moved to the tip of opus/issue-220, re-imported, then the #207 gate
rem scene (res://bench/scene_gate.tscn, 1080p, the engagement camera) in two launches of 3 sessions each.
rem Copy this file, set L (the run's label), M (the modes) and X (extra probe arguments, or leave it empty), and A=1
rem to rebuild the generated assets first. Output: Downloads\voidsworn_test\opus220\out\<label>_1 and _2.
setlocal
set "L=LABEL"
set "M=base,deaths"
set "X=--trace"
set "A=0"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "R=%VT%\opus207\repo"
set "O=%VT%\opus220\out"
set /p G=<"%VT%\godot_path.txt"
if not exist "%O%" mkdir "%O%"
if not exist "%R%\.git" (
  echo %L% no clone >> "%O%\status.txt"
  exit /b 1
)
echo %L% start %date% %time% >> "%O%\status.txt"
git -C "%R%" fetch --depth 1 origin opus/issue-220 > "%O%\%L%_git.txt" 2>&1
git -C "%R%" reset --hard FETCH_HEAD >> "%O%\%L%_git.txt" 2>&1
git -C "%R%" log -1 --format=%%H > "%O%\%L%_commit.txt" 2>&1
set "TMO=%R%\tools\pc\tmo.bat"
set "Q=--query-gpu=name,driver_version,utilization.gpu,clocks.gr,clocks.mem,temperature.gpu,power.draw,pstate,memory.used"
nvidia-smi %Q% --format=csv > "%O%\%L%_gpu.txt" 2>&1
tasklist /fi "imagename eq Godot*" > "%O%\%L%_tasks.txt" 2>&1
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\%L%_import.txt" 2>&1
if "%A%"=="1" call "%TMO%" 2400 "%G%" --headless --path "%R%\godot" --script res://render/build_assets.gd -- --repo "%R%" --hi "%VT%\enginetest\assets\hi" --env "%VT%\enginetest\assets\env" > "%O%\%L%_assets.txt" 2>&1
echo %L% bench %time% >> "%O%\status.txt"
for %%N in (1 2) do (
  call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\%L%_%%N" --modes %M% --sessions 3 %X% > "%O%\%L%_%%N_log.txt" 2>&1
  nvidia-smi %Q% --format=csv,noheader >> "%O%\%L%_gpu.txt" 2>&1
)
echo %L% done %date% %time% >> "%O%\status.txt"
cd /d "%VT%\build"
exit /b 0
