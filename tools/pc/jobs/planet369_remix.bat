@echo off
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "PY369="
if exist "%VT%\python_path.txt" set /p PY369=<"%VT%\python_path.txt"
if not defined PY369 exit /b 2
call "%~dp0..\tmo.bat" 1200 "%PY369%" "%~dp0planet369_remix.py" %*
if errorlevel 1 exit /b 1
call "%~dp0..\tmo.bat" 120 "%VT%\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --log-file "%TEMP%\planet369_pack_engine.log" --path "%~dp0..\..\..\godot" --script "%~dp0planet369_pack.gd"
exit /b %ERRORLEVEL%
