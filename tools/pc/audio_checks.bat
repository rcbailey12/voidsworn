@echo off
rem Double-click for the sound, 20-ship salvo and existing music checks.
rem Optional: set GODOT_EXE to the console exe, or pass its full path as argument 1.
setlocal
set "ROOT=%~dp0..\.."
set "G=%~1"
if not defined G set "G=%GODOT_EXE%"
if not defined G if exist "%~dp0godot_path.txt" set /p G=<"%~dp0godot_path.txt"
if not defined G if exist "%ROOT%\..\godot_path.txt" set /p G=<"%ROOT%\..\godot_path.txt"
if not defined G if exist "%USERPROFILE%\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe" set "G=%USERPROFILE%\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%G%" (
  echo FAIL: Godot console exe not found. Set GODOT_EXE to its full path.
  pause
  exit /b 1
)
set "OUT=%ROOT%\godot\audio\test\results"
if not exist "%OUT%" mkdir "%OUT%"
set "FAILS=0"
call :check audio res://audio/test/audio_check.gd "AUDIO CHECK PASS"
call :check salvo res://audio/test/salvo_check.gd "SALVO CHECK PASS"
call :check music res://music/test/music_check.gd "MUSIC CHECK PASS"
echo.
echo Failed checks: %FAILS%. Logs: %OUT%
set "RESULT=%FAILS%"
if not "%~2"=="nopause" pause
exit /b %RESULT%

:check
echo Running %~1 check...
"%G%" --headless --path "%ROOT%\godot" --log-file "%OUT%\%~1_engine.log" --script %~2 > "%OUT%\%~1.log" 2>&1
if errorlevel 1 goto :failed
findstr /x /c:%3 "%OUT%\%~1.log" >nul
if errorlevel 1 goto :failed
echo   PASS
exit /b 0
:failed
echo   FAIL: see %OUT%\%~1.log
set /a FAILS+=1 >nul
exit /b 0
