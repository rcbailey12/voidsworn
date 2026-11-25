@echo off
rem Issue 1360: bake the three storm lightning bolts (bake_storm_bolts.py) and pack them into godot\fx\atlases\storm.
rem Double-click. Frames go to %%TEMP%%\voidsworn-storm-bolts unless a folder is given. Blender runs through the
rem timeout runner, which claims a shared GPU slot (Blender weighs 2) and releases it on exit. Nothing is deleted.
setlocal
cd /d "%~dp0..\..\.."
set "ROOT=%USERPROFILE%\Downloads\voidsworn_test"
set "OUT=%TEMP%\voidsworn-storm-bolts"
if not "%~1"=="" set "OUT=%~1"
call tools\pc\tmo.bat 1800 "%ROOT%\blender\blender-4.5.14-windows-x64\blender.exe" -b -t 8 -P tools/blender/vfx/bake_storm_bolts.py -- "%OUT%" --pack godot/fx/atlases/storm
exit /b %ERRORLEVEL%
