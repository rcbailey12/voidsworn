@echo off
rem Issue 61 review gate. Run on lane A, not CPU-only lane B.
setlocal
set "ROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "REPO=%ROOT%\board\repo"
set "SHOTS=%ROOT%\board\issue-61\shots\r91"
set /p BLENDER=<"%ROOT%\blender_path.txt"
if not exist "%SHOTS%" mkdir "%SHOTS%"
if /i "%~1"=="--preview-only" goto :preview
call "%REPO%\tools\pc\tmo.bat" 1200 "%BLENDER%" -b -t 12 --python-exit-code 1 -P "%REPO%\tools\blender\hs\station_kit.py" -- --out "%SHOTS%" --ships "%ROOT%\a4\godot_hi"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :done
:preview
if not exist "%TEMP%\issue61_station_probe" mkdir "%TEMP%\issue61_station_probe"
> "%TEMP%\issue61_station_probe\project.godot" echo config_version=5
call "%REPO%\tools\pc\tmo.bat" 120 "%ROOT%\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path "%TEMP%\issue61_station_probe" --log-file "%TEMP%\issue61_godot_engine.log" --script "%REPO%\tools\blender\hs\station_check.gd" -- "%SHOTS%"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :done
call "%REPO%\tools\pc\tmo.bat" 300 "%ROOT%\godot\Godot_v4.7.2-stable_win64_console.exe" --path "%ROOT%\build\godot" --windowed --resolution 960x540 --position -8000,-8000 --log-file "%TEMP%\issue61_preview_engine.log" --script "%REPO%\tools\blender\hs\station_preview.gd" -- "%SHOTS%" "%REPO%\godot"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :done
call "%REPO%\tools\pc\tmo.bat" 120 "%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe" "%REPO%\tools\blender\hs\station_sheets.py" "%SHOTS%"
set "RC=%ERRORLEVEL%"
:done
cd /d "%ROOT%\build"
exit /b %RC%
