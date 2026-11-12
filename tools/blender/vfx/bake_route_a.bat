@echo off
rem Issue 353: bake route A (see bake_route_a.py) for the weapon impact and the ship-death flash, then pack both fire
rem amounts into atlases laid out like godot\fx\atlases (pack_routes.py). Double-click; output goes to %%TEMP%%\voidsworn-route-a
rem unless a folder is given. The game does not use these unless the bench switch VS_FX_ATLAS points at one. Nothing is deleted.
setlocal
cd /d "%~dp0..\..\.."
set "ROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "OUT=%TEMP%\voidsworn-route-a"
if not "%~1"=="" set "OUT=%~1"
call tools\pc\tmo.bat 5400 "%ROOT%\blender\blender-4.5.14-windows-x64\blender.exe" -b -t 0 -P tools/blender/vfx/bake_route_a.py -- "%OUT%\bake" --resolution 256 --kinds impact
if errorlevel 1 exit /b 1
call tools\pc\tmo.bat 5400 "%ROOT%\blender\blender-4.5.14-windows-x64\blender.exe" -b -t 0 -P tools/blender/vfx/bake_route_a.py -- "%OUT%\bake" --resolution 256 --kinds flash
if errorlevel 1 exit /b 1
"%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe" tools/blender/vfx/pack_routes.py "%OUT%\bake" "%OUT%\atlases" --route a
exit /b %ERRORLEVEL%
