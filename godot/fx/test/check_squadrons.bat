@echo off
setlocal
rem Isolated checks and review captures. The installed play build is only read.
set "VSROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "G=%VSROOT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "RESULT=%TEMP%\voidsworn-squadrons-%RANDOM%"
set "P=%RESULT%\project"
if not defined SQUADRON_OUT set "SQUADRON_OUT=%VSROOT%\board\issue-67\shots"
mkdir "%P%\.godot\imported" 2>nul
mkdir "%P%\.godot\shader_cache" 2>nul
robocopy "%~dp0..\.." "%P%" /E /XD .godot gen /NFL /NDL /NJH /NJS >nul
if errorlevel 8 goto failed
mklink /J "%P%\gen" "%VSROOT%\build\godot\gen" >nul
if errorlevel 1 goto failed
robocopy "%VSROOT%\build\godot\assets\ships" "%P%\assets\ships" *.jpg *.jpg.import /S /NFL /NDL /NJH /NJS >nul
if errorlevel 8 goto failed
for /d %%D in ("%VSROOT%\build\godot\assets\ships\*") do (
  robocopy "%VSROOT%\build\godot\.godot\imported" "%P%\.godot\imported" %%~nxD*.ctex /NFL /NDL /NJH /NJS >nul
  if errorlevel 8 goto failed
)
call "%~dp0..\..\..\tools\pc\tmo.bat" 180 "%G%" --headless --path "%P%" --script res://fx/test/squadron_check.gd --log-file "%RESULT%\check.log"
if errorlevel 1 goto failed
findstr /c:"SCRIPT ERROR:" "%RESULT%\check.log" >nul
if not errorlevel 1 goto failed
call "%~dp0..\..\..\tools\pc\tmo.bat" 240 "%G%" --path "%P%" --rendering-method forward_plus --script res://fx/test/squadron_probe.gd --resolution 640x360 --log-file "%RESULT%\capture.log"
if errorlevel 1 goto failed
findstr /c:"SCRIPT ERROR:" "%RESULT%\capture.log" >nul
if not errorlevel 1 goto failed
set "PY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
if not exist "%PY%" goto failed
"%PY%" "%~dp0squadron_sheets.py" "%SQUADRON_OUT%"
if errorlevel 1 goto failed
echo PASS. Review captures: %SQUADRON_OUT%
echo Logs: %RESULT%
if not defined FX_CHECK_UNATTENDED pause
exit /b 0
:failed
echo Squadron check failed. Logs: %RESULT%
if not defined FX_CHECK_UNATTENDED pause
exit /b 1
