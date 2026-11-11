@echo off
setlocal
cd /d "%~dp0..\..\.."
set "G=%~1"
if not defined G set "G=%USERPROFILE%\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%G%" (
  echo Godot was not found. Drag its console exe onto this bat to run the checks.
  pause
  exit /b 2
)
set "RESULT=%TEMP%\voidsworn-destruction-%RANDOM%"
if defined FX_CHECK_OUT set "RESULT=%FX_CHECK_OUT%"
if not exist "%RESULT%\.runtime" mkdir "%RESULT%\.runtime"
set "APPDATA=%RESULT%\.runtime"
set "LOCALAPPDATA=%APPDATA%"
set "DESTRUCTION_OUT="
"%G%" --headless --path godot --script res://fx/test/destruction_steps_check.gd --log-file "%RESULT%\geometry.log"
if errorlevel 1 goto failed
"%G%" --headless --path godot --script res://fx/test/death_plane_check.gd --log-file "%RESULT%\plane.log"
if errorlevel 1 goto failed
"%G%" --headless --path godot --script res://fx/test/destruction_staging_check.gd --log-file "%RESULT%\staging.log"
if errorlevel 1 goto failed
"%G%" --headless --path godot --script res://fx/test/fx_smoke.gd --log-file "%RESULT%\smoke.log"
if errorlevel 1 goto failed
"%G%" --headless --path godot --script res://fx/test/flash_area_check.gd --log-file "%RESULT%\flash_area.log"
if errorlevel 1 goto failed
"%G%" --headless --path godot --script res://fx/test/death_spawn_check.gd --log-file "%RESULT%\death_spawn.log"
if errorlevel 1 goto failed
"%G%" --headless --path godot --script res://fx/test/playtest_batch1_check.gd --log-file "%RESULT%\playtest_batch1.log"
if errorlevel 1 goto failed
"%G%" --headless --path godot --script res://world/test_blockers.gd --log-file "%RESULT%\blockers.log"
if errorlevel 1 goto failed
set "PROBE_BOX=1"
set "PROBE_W=1920"
set "PROBE_H=1080"
set "PROBE_HULK="
set "PROBE_OUT=%RESULT%\box"
if not exist "%PROBE_OUT%" mkdir "%PROBE_OUT%"
"%G%" --path godot --fixed-fps 60 --script res://fx/test/fx_inside_probe.gd --log-file "%PROBE_OUT%\probe.log"
if errorlevel 1 goto failed
set "PROBE_OUT=%RESULT%\fleet"
if not exist "%PROBE_OUT%" mkdir "%PROBE_OUT%"
"%G%" --path godot --fixed-fps 60 --script res://fx/test/destruction_fleet_probe.gd --log-file "%PROBE_OUT%\probe.log"
if errorlevel 1 goto failed
echo Checks finished. Logs and screenshots: %RESULT%
if not defined FX_CHECK_UNATTENDED pause
exit /b 0
:failed
echo A check failed. See the log in %RESULT%.
if not defined FX_CHECK_UNATTENDED pause
exit /b 1
