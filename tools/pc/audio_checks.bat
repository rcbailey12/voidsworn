@echo off
rem Double-click for the sound, 20-ship salvo, sound mix (issue 2034) and existing music checks.
rem Optional: set GODOT_EXE to the console exe, or pass its full path as argument 1.
setlocal enableextensions disabledelayedexpansion
set "ROOT=%~dp0..\.."
set "GODOT=%~1"
if not defined GODOT set "GODOT=%GODOT_EXE%"
if not defined GODOT if exist "%~dp0godot_path.txt" set /p GODOT=<"%~dp0godot_path.txt"
set "NODE="
for %%D in ("%ROOT%") do set "SEARCH=%%~fD"
rem Find the PC bundle above build or any board lane checkout, as in parity.bat.
:bundle
if not defined NODE if exist "%SEARCH%\node\node.exe" set "NODE=%SEARCH%\node\node.exe"
if not defined GODOT if exist "%SEARCH%\godot_path.txt" set /p GODOT=<"%SEARCH%\godot_path.txt"
for %%D in ("%SEARCH%\..") do set "NEXT=%%~fD"
if /i "%NEXT%"=="%SEARCH%" goto :bundle_done
set "SEARCH=%NEXT%"
goto :bundle
:bundle_done
if not defined GODOT if exist "%USERPROFILE%\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe" set "GODOT=%USERPROFILE%\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT%" (
  echo FAIL: Godot console exe not found. Set GODOT_EXE to its full path.
  pause
  exit /b 1
)
set "OUT=%ROOT%\godot\audio\test\results"
if not exist "%OUT%" mkdir "%OUT%"
set "FAILS=0"
call :check audio res://audio/test/audio_check.gd "AUDIO CHECK PASS"
call :check salvo res://audio/test/salvo_check.gd "SALVO CHECK PASS"
call :check mix2034 res://audio/test/mix_2034_check.gd "MIX 2034 CHECK PASS"
call :check music res://music/test/music_check.gd "MUSIC CHECK PASS"
echo.
echo Failed checks: %FAILS%. Logs: %OUT%
set "RESULT=%FAILS%"
if not "%~2"=="nopause" pause
exit /b %RESULT%

:check
echo Running %~1 check...
"%GODOT%" --headless --path "%ROOT%\godot" --log-file "%OUT%\%~1_engine.log" --script %~2 > "%OUT%\%~1.log" 2>&1
if errorlevel 1 goto :failed
findstr /x /c:%3 "%OUT%\%~1.log" >nul
if errorlevel 1 goto :failed
echo   PASS
exit /b 0
:failed
echo   FAIL: see %OUT%\%~1.log
set /a FAILS+=1 >nul
exit /b 0
