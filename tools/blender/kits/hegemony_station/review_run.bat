@echo off
rem Refs #373. Review only: no install, no live board changes, no deletions.
setlocal
for %%I in ("%~dp0..\..\..\..") do set "REPO=%%~fI"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "OUT=%VT%\board_b\issue-373\shots\review8"
set "GD=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "BLENDER=%VT%\blender\blender-4.5.14-windows-x64\blender.exe"
set "PY=%VT%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe"
set "KIT=%~dp0"
set "SHEET_DEVICE=CPU"
set "GO="
if not exist "%VT%\gpu_go.txt" goto :failed
set /p "GO=" < "%VT%\gpu_go.txt"
echo %GO% | findstr /b /c:"GPU cleared" >nul
if errorlevel 1 goto :failed
if not exist "%OUT%" mkdir "%OUT%"
call "%REPO%\tools\pc\tmo.bat" 300 "%GD%" --headless --path "%REPO%\godot" --log-file "%TEMP%\station373_probe_engine.log" --script "%KIT%inspect.gd" -- "%OUT%\game_inputs.json"
if errorlevel 1 goto :failed
call "%REPO%\tools\pc\tmo.bat" 1200 "%BLENDER%" -b -t 8 --python-exit-code 1 -P "%KIT%review.py" -- --out "%OUT%"
if errorlevel 1 goto :failed
"%PY%" "%KIT%check.py" "%OUT%"
if errorlevel 1 goto :failed
"%PY%" "%KIT%range_selftest.py" "%OUT%"
if errorlevel 1 goto :failed
rem Captures require the real renderer; rules and measurements above are headless.
call "%REPO%\tools\pc\tmo.bat" 300 "%GD%" --rendering-method forward_plus --windowed --resolution 1280x720 --path "%REPO%\godot" --log-file "%TEMP%\station373_capture_engine.log" --script "%KIT%capture.gd" -- "%OUT%"
if errorlevel 1 goto :failed
rem Repeat after shader warm-up and keep the second captures (RULEBOOK 12.5).
call "%REPO%\tools\pc\tmo.bat" 300 "%GD%" --rendering-method forward_plus --windowed --resolution 1280x720 --path "%REPO%\godot" --log-file "%TEMP%\station373_capture_engine2.log" --script "%KIT%capture.gd" -- "%OUT%"
if errorlevel 1 goto :failed
"%PY%" "%KIT%check.py" "%OUT%" --gpu
if errorlevel 1 goto :failed
"%PY%" "%KIT%sheets.py" "%OUT%"
if errorlevel 1 goto :failed
echo T2 review8 complete. Pictures and reports: %OUT%. Nothing installed.
if not "%RECIPE_NOPAUSE%"=="1" pause
exit /b 0
:failed
echo T2 review8 FAILED. Check GPU clearance and the command above. Nothing installed.
if not "%RECIPE_NOPAUSE%"=="1" pause
exit /b 1
