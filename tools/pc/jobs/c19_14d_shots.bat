@echo off
set L=..\smoke_log.txt
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set NODE="%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
set IO=%USERPROFILE%\Downloads\voidsworn_test\comfy_io\C19_51
set CONCEPT=%USERPROFILE%\Downloads\voidsworn_meshes\picks\flux11_C19_51_cut.png
echo --- v14d: no double AO on finish maps (shots only) --- >> %L%
"%PYEXE%" build.py test >> %L% 2>&1
if not exist shots_v56d mkdir shots_v56d
set OUT=shots_v56d
set TPLS=c_boss
set ZOOM=1.0,0.5
set MAP=belt
set TAG=belt
"%PYEXE%" closeshot.py >> %L% 2>&1
set ONLY=desk
set ZOOM=1.0
set MAP=planet
set TAG=planet
"%PYEXE%" closeshot.py >> %L% 2>&1
set MAP=belt
set PRE=
set TPLS=warden,h_dominion,c_hulk,i_boss
set TAG=fleet
"%PYEXE%" closeshot.py >> %L% 2>&1
set ONLY=
set MAP=
set OUT=
set TAG=
set TPLS=
set ZOOM=
echo --- v14d done --- >> %L%
cd /d "%~dp0"
