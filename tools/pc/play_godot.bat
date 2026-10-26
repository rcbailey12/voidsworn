@echo off
rem Play Voidsworn in Godot. Double-click this file.
rem The first time, it prepares the ship, rock and sky files for Godot (about a minute), then the game opens.
rem Works from Downloads\voidsworn_test (the game is in build\, the Godot project in build\godot\)
rem or from a repo checkout (tools\pc\play_godot.bat). If an exported Voidsworn.exe exists, it runs that instead.
rem play_godot_safe.bat runs the same in the simpler Compatibility renderer, for a PC where the game will not start.
setlocal
set "HERE=%~dp0"
set "ROOT="
if exist "%HERE%build\godot\project.godot" set "ROOT=%HERE%build\"
if not defined ROOT if exist "%HERE%..\..\godot\project.godot" set "ROOT=%HERE%..\..\"
if not defined ROOT (
  echo Cannot find the Godot project ^(build\godot\project.godot^).
  pause
  exit /b 1
)
if exist "%ROOT%export\Voidsworn.exe" (
  start "" "%ROOT%export\Voidsworn.exe" %*
  exit /b 0
)
set "G="
if exist "%HERE%godot_path.txt" set /p G=<"%HERE%godot_path.txt"
if not defined G if exist "%ROOT%..\godot_path.txt" set /p G=<"%ROOT%..\godot_path.txt"
if not defined G (
  echo Cannot find godot_path.txt ^(it holds the path to the Godot exe^).
  pause
  exit /b 1
)
rem the window version of Godot (no black console), when it sits beside the console one
set "GW=%G:_console.exe=.exe%"
if not exist "%GW%" set "GW=%G%"
set "HI="
if exist "%ROOT%contrib\opus\enginetest\assets\hi" set "HI=%ROOT%contrib\opus\enginetest\assets\hi"
if exist "%ROOT%..\enginetest\assets\hi" set "HI=%ROOT%..\enginetest\assets\hi"
set "ENV="
if exist "%ROOT%..\enginetest\assets\env" set "ENV=%ROOT%..\enginetest\assets\env"
if not exist "%ROOT%godot\gen\v3.txt" (
  echo Preparing ships, rocks and sky for Godot. This happens once and takes about a minute...
  "%G%" --headless --path "%ROOT%godot" --script res://render/build_assets.gd -- --repo "%ROOT%." --hi "%HI%" --env "%ENV%" > "%ROOT%godot\build_assets_log.txt" 2>&1
)
start "" "%GW%" --path "%ROOT%godot" %*
exit /b 0
