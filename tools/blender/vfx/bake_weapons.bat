@echo off
setlocal
cd /d "%~dp0..\..\.."
set "ROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "BAKE=%TEMP%\voidsworn-weapons-bake"
if not "%~1"=="" set "BAKE=%~1"
call tools\pc\tmo.bat 1800 "%ROOT%\blender\blender-4.5.14-windows-x64\blender.exe" -b -t 8 -P tools/blender/vfx/bake_weapons.py -- "%BAKE%"
if errorlevel 1 exit /b 1
"%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe" tools/blender/vfx/pack_weapons.py "%BAKE%" godot/fx/atlases/weapons
exit /b %ERRORLEVEL%
