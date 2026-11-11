@echo off
rem Issue 426: the production B core, three seeds, native staging-table cells. Nothing is deleted.
setlocal
cd /d "%~dp0..\..\.."
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "OUT=%TEMP%\voidsworn-rebake"
if not "%~1"=="" set "OUT=%~1"
"%VT%\blender\blender-4.5.14-windows-x64\blender.exe" -b -t 8 -P tools/blender/vfx/bake_route_b.py -- "%OUT%" --resolution 128 --tile 768 --seeds 3
if errorlevel 1 exit /b 1
"%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe" tools/blender/vfx/pack_routes.py "%OUT%" godot/fx/atlases/rebake --route b --production
exit /b %ERRORLEVEL%
