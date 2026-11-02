@echo off
setlocal
cd /d "%~dp0"
set "GODOT="
if exist "%USERPROFILE%\Downloads\voidsworn_test\godot_path.txt" set /p GODOT=<"%USERPROFILE%\Downloads\voidsworn_test\godot_path.txt"
if not defined GODOT (echo FAIL: Godot console path not found. & exit /b 1)
set "NODE=%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
if not exist "%NODE%" (echo FAIL: project Node 22 runtime not found. & exit /b 1)
"%NODE%" --preserve-symlinks --preserve-symlinks-main tools\test_onboarding.js "%GODOT%"
set "RESULT=%ERRORLEVEL%"
if /i not "%~1"=="nopause" pause
exit /b %RESULT%
