@echo off
setlocal
rem Isolated R80 wing checks and real-battle captures. No play build changes.
set "VSROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "G=%VSROOT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "RESULT=%TEMP%\voidsworn-squadrons-%RANDOM%"
set "P=%RESULT%\project"
if not defined SQUADRON_OUT set "SQUADRON_OUT=%VSROOT%\board\issue-67\shots"
set "SQUADRON_FRAMES=%RESULT%\frames"
set "SQUADRON_FACTION="
set "SQUADRON_BATTLE_ONLY="
set "APPDATA=%RESULT%\userdata"
mkdir "%P%\.godot\imported" 2>nul
mkdir "%APPDATA%" 2>nul
robocopy "%~dp0..\.." "%P%" /E /XD .godot gen /NFL /NDL /NJH /NJS >nul
if errorlevel 8 goto failed
mklink /J "%P%\gen" "%VSROOT%\build\godot\gen" >nul
if errorlevel 1 goto failed
robocopy "%VSROOT%\build\godot\assets\ships" "%P%\assets\ships" *.jpg *.jpg.import /S /NFL /NDL /NJH /NJS >nul
if errorlevel 8 goto failed
robocopy "%VSROOT%\build\godot\.godot\imported" "%P%\.godot\imported" *.ctex *.scn *.fontdata /NFL /NDL /NJH /NJS >nul
if errorlevel 8 goto failed
for %%T in (squadron_check damage_surface_check playtest_batch3_check fx_smoke) do (
  call "%~dp0..\..\..\tools\pc\tmo.bat" 180 "%G%" --headless --path "%P%" --script res://fx/test/%%T.gd --log-file "%RESULT%\%%T.log"
  if errorlevel 1 goto failed
)
call "%~dp0..\..\..\tools\pc\tmo.bat" 600 "%G%" --path "%P%" --script res://fx/test/squadron_probe.gd --resolution 640x360 --log-file "%RESULT%\capture.log"
if errorlevel 1 goto failed
findstr /C:"SCRIPT ERROR:" /C:"ERROR: Failed loading" "%RESULT%\capture.log" >nul
if not errorlevel 1 goto failed
findstr /C:"SQUADRON_CAPTURE_COMPLETE" "%RESULT%\capture.log" >nul
if errorlevel 1 goto failed
set "PY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
if exist "%PY%" (
  "%PY%" "%~dp0squadron_sheets.py" "%SQUADRON_OUT%" "%SQUADRON_FRAMES%"
  if errorlevel 1 goto failed
)
echo PASS. Review captures: %SQUADRON_OUT%
echo Scratch logs: %RESULT%
if not defined FX_CHECK_UNATTENDED pause
exit /b 0
:failed
echo A squadron check failed. Logs: %RESULT%
if not defined FX_CHECK_UNATTENDED pause
exit /b 1
