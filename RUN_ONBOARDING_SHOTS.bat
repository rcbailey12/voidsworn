@echo off
setlocal
cd /d "%~dp0"
set "GODOT="
if exist "%USERPROFILE%\Downloads\voidsworn_test\godot_path.txt" set /p GODOT=<"%USERPROFILE%\Downloads\voidsworn_test\godot_path.txt"
if not defined GODOT (echo FAIL: Godot console path not found. & exit /b 1)
set "APPDATA=%CD%\.onboarding_checks\visual_appdata"
if not exist "%APPDATA%" mkdir "%APPDATA%"
"%GODOT%" --path godot --rendering-method gl_compatibility --audio-driver Dummy --windowed --resolution 1920x1080 --log-file "%CD%\.onboarding_checks\visual.log" --script res://campaign/test/onboarding_visual.gd -- "%CD%\contrib\codex\onboarding_2026_11\shots"
if errorlevel 1 exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\onboarding_sheets.ps1
set "RESULT=%ERRORLEVEL%"
if /i not "%~1"=="nopause" pause
exit /b %RESULT%
