@echo off
setlocal
rem Isolated R80 checks and real-hull captures. Nothing in the play build is changed.
set "VSROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "G=%VSROOT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "RESULT=%TEMP%\voidsworn-damage-%RANDOM%"
if defined DAMAGE_CHECK_OUT set "RESULT=%DAMAGE_CHECK_OUT%"
set "P=%RESULT%\project"
mkdir "%P%\.godot\imported" 2>nul
mkdir "%P%\.godot\shader_cache" 2>nul
robocopy "%~dp0..\.." "%P%" /E /XD .godot gen /NFL /NDL /NJH /NJS >nul
if errorlevel 8 goto failed
if not exist "%P%\gen" mklink /J "%P%\gen" "%VSROOT%\build\godot\gen" >nul
robocopy "%VSROOT%\build\godot\assets\ships" "%P%\assets\ships" *.jpg *.jpg.import /S /NFL /NDL /NJH /NJS >nul
if errorlevel 8 goto failed
for /d %%D in ("%VSROOT%\build\godot\assets\ships\*") do (
  robocopy "%VSROOT%\build\godot\.godot\imported" "%P%\.godot\imported" %%~nxD*.ctex /NFL /NDL /NJH /NJS >nul
  if errorlevel 8 goto failed
)
call "%~dp0..\..\..\tools\pc\tmo.bat" 180 "%G%" --headless --path "%P%" --script res://fx/test/damage_surface_check.gd --log-file "%RESULT%\check.log"
if errorlevel 1 goto failed
set "DAMAGE_OUT=%RESULT%\shots"
set "DAMAGE_MODE=capture"
set "DAMAGE_LABEL=final"
set "DAMAGE_FACTIONS="
call "%~dp0..\..\..\tools\pc\tmo.bat" 600 "%G%" --path "%P%" --script res://fx/test/damage_surface_probe.gd --resolution 640x360 --log-file "%RESULT%\capture.log"
if errorlevel 1 goto failed
set "DAMAGE_OUT=%RESULT%\fleet"
set "DAMAGE_MODE=fleet"
call "%~dp0..\..\..\tools\pc\tmo.bat" 600 "%G%" --path "%P%" --script res://fx/test/damage_surface_probe.gd --resolution 640x360 --log-file "%RESULT%\fleet.log"
if errorlevel 1 goto failed
set "DAMAGE_OUT=%RESULT%\safe"
set "DAMAGE_MODE=capture"
set "DAMAGE_LABEL=safe"
set "DAMAGE_FACTIONS=hegemony,chorus"
call "%~dp0..\..\..\tools\pc\tmo.bat" 180 "%G%" --path "%P%" --rendering-method gl_compatibility --script res://fx/test/damage_surface_probe.gd --resolution 640x360 --log-file "%RESULT%\safe.log"
if errorlevel 1 goto failed
set "PY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
if exist "%PY%" (
  "%PY%" "%~dp0damage_surface_sheets.py" "%RESULT%\shots" "%RESULT%\sheets" final
  "%PY%" "%~dp0damage_surface_sheets.py" "%RESULT%\safe" "%RESULT%\sheets" safe
)
echo PASS. Screenshots and measured frame cost: %RESULT%
if not defined FX_CHECK_UNATTENDED pause
exit /b 0
:failed
echo A damage check failed. Logs: %RESULT%
if not defined FX_CHECK_UNATTENDED pause
exit /b 1
