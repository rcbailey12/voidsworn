@echo off
rem Issue 220: before and after stills for the screenshot verdict (Opus). Queue job.
rem The gate scene's --still mode (fixed effect clock, workers settled each step, same seed) on Opus's #207 clone:
rem twice with this branch's effects code (after_1, after_2), then twice with main's effects code (before_1, before_2;
rem only godot\fx is taken from main, the probe stays this branch's), then the clone is put back on the branch.
rem Two runs of the same code show the noise floor (debris physics runs on real time); before against after shows
rem the change. Output: Downloads\voidsworn_test\opus220\out\stills_<label>\.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "R=%VT%\opus207\repo"
set "O=%VT%\opus220\out"
set /p G=<"%VT%\godot_path.txt"
if not exist "%O%" mkdir "%O%"
echo stills start %date% %time% >> "%O%\status.txt"
git -C "%R%" fetch --depth 1 origin opus/issue-220 > "%O%\stills_git.txt" 2>&1
git -C "%R%" reset --hard FETCH_HEAD >> "%O%\stills_git.txt" 2>&1
git -C "%R%" log -1 --format=%%H > "%O%\stills_commit.txt" 2>&1
set "TMO=%R%\tools\pc\tmo.bat"
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\stills_import_after.txt" 2>&1
for %%N in (1 2) do call "%TMO%" 600 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\stills_after_%%N" --still > "%O%\stills_after_%%N_log.txt" 2>&1
git -C "%R%" fetch --depth 1 origin main >> "%O%\stills_git.txt" 2>&1
git -C "%R%" checkout FETCH_HEAD -- godot/fx >> "%O%\stills_git.txt" 2>&1
git -C "%R%" diff --stat HEAD -- godot/fx > "%O%\stills_before_diff.txt" 2>&1
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\stills_import_before.txt" 2>&1
for %%N in (1 2) do call "%TMO%" 600 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%O%\stills_before_%%N" --still > "%O%\stills_before_%%N_log.txt" 2>&1
git -C "%R%" checkout HEAD -- godot/fx >> "%O%\stills_git.txt" 2>&1
git -C "%R%" status --short > "%O%\stills_status_after.txt" 2>&1
echo stills done %date% %time% >> "%O%\status.txt"
cd /d "%VT%\build"
exit /b 0
