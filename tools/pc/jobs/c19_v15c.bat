@echo off
set L=..\smoke_log.txt
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set NODE="%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
set IO=%USERPROFILE%\Downloads\voidsworn_test\comfy_io\C19_51\v15
echo --- v15c: bolted salvage panels, no painted patches (step 3) --- >> %L%
set PAINT=proc
set PATCH=
set OCC=%IO%\v15_kit.glb
set EXPORT=%IO%\shell_painted.glb
%BL% -b --factory-startup -P project_paint.py -- "%IO%\v15_shell.glb" "%IO%\shell_albproj.png" 4096 > "%IO%\shellproj_log.txt" 2>&1
type "%IO%\shellproj_log.txt" | findstr /i /c:"baked" /c:"Error" /c:"Traceback" >> %L%
set OCC=%IO%\v15_shell.glb
set EXPORT=%IO%\kit_painted.glb
set AOD=.015
%BL% -b --factory-startup -P project_paint.py -- "%IO%\v15_kit.glb" "%IO%\kit_albproj.png" 4096 > "%IO%\kitproj_log.txt" 2>&1
type "%IO%\kitproj_log.txt" | findstr /i /c:"baked" /c:"Error" /c:"Traceback" >> %L%
set OCC=
set EXPORT=
set AOD=
set PAINT=
set PATCH=
set PAINTK=1.0
set KIT=%IO%\kit_painted.glb
set FIN=%IO%\shell_albproj
set KFIN=%IO%\kit_albproj
%PY% -s pixal_to_game.py "%IO%\shell_painted.glb" hulls_hi C19_51 left 4096 >> %L% 2>&1
%PY% -s pixal_to_game.py "%IO%\shell_painted.glb" hulls C19_51 left 2048 >> %L% 2>&1
set KIT=
set FIN=
set KFIN=
set PAINTK=
%NODE% vsm_pack.mjs hulls_hi C19_51 >> %L% 2>&1
%NODE% vsm_pack.mjs hulls C19_51 >> %L% 2>&1
del /q hulls_hi\C19_51.vb hulls_hi\C19_51.ib hulls\C19_51.vb hulls\C19_51.ib 2>nul
"%PYEXE%" build.py test >> %L% 2>&1
if not exist shots_v15c mkdir shots_v15c
set OUT=shots_v15c
set TPLS=c_boss
set ONLY=desk
set ZOOM=1.0,0.5,1.6
set MAP=belt
set TAG=belt
"%PYEXE%" closeshot.py >> %L% 2>&1
set ZOOM=1.0
set MAP=planet
set TAG=planet
"%PYEXE%" closeshot.py >> %L% 2>&1
set ZOOM=1.6
set MAP=belt
set TPLS=c_boss,h_dominion,c_hulk,warden
set TAG=fleet
"%PYEXE%" closeshot.py >> %L% 2>&1
set OUT=
set TAG=
set TPLS=
set ONLY=
set ZOOM=
set MAP=
echo --- v15c done --- >> %L%
cd /d "%~dp0"
