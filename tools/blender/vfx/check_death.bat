@echo off
setlocal
rem Optional first argument: an isolated Godot project with imported assets.
cd /d "%~dp0..\..\.."
set "PROJECT=%~1"
if not defined PROJECT set "PROJECT=%CD%\godot"
set "G=%USERPROFILE%\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe"
set "RESULT=%TEMP%\voidsworn-137-checks"
if not exist "%RESULT%" mkdir "%RESULT%"
set "APPDATA=%RESULT%\runtime"
set "LOCALAPPDATA=%APPDATA%"
for %%T in (destruction_steps_check death_plane_check destruction_staging_check fx_smoke damage_surface_check death_leap_check) do (
  call tools\pc\tmo.bat 180 "%G%" --headless --fixed-fps 60 --path "%PROJECT%" --script res://fx/test/%%T.gd --log-file "%RESULT%\%%T.log" > "%RESULT%\%%T.stdout" 2>&1
  if errorlevel 1 goto failed
  echo PASS %%T
)
echo PASS: death checks. Logs: %RESULT%
exit /b 0
:failed
echo FAIL: see %RESULT%
exit /b 1
