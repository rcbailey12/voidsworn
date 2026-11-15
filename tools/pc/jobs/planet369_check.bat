@echo off
setlocal
set "R369=%~dp0..\..\.."
set "G369=%USERPROFILE%\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe"
call "%~dp0..\tmo.bat" 240 "%G369%" --headless --log-file "%TEMP%\planet369_godot.log" --path "%R369%\godot" --script "%~dp0planet369_check.gd"
exit /b %ERRORLEVEL%
