@echo off
set L=..\smoke_log.txt
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set NODE="%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
set IO=%USERPROFILE%\Downloads\voidsworn_test\comfy_io\C19_51
if not exist node_modules\meshoptimizer mkdir node_modules\meshoptimizer
copy /y mo\*.* node_modules\meshoptimizer\ >nul
if not exist "%IO%\lod" mkdir "%IO%\lod"
echo --- v54 test: Pixal3D Pyre-Barge in game --- >> %L%
%BL% -b --factory-startup -P lod_make.py -- "%IO%\mesh\C19_51E2_pixal_tex_00001_.glb" "%IO%\lod\E2" 250000 > "%IO%\lod\lod_log.txt" 2>&1
set ALB=%IO%\proj\E2_albproj.png
%PY% -s pixal_to_game.py "%IO%\mesh\C19_51E2_pixal_tex_00001_.glb" hulls_hi C19_51 left 4096 >> %L% 2>&1
%PY% -s pixal_to_game.py "%IO%\lod\E2_250000.glb" hulls C19_51 left 2048 >> %L% 2>&1
set ALB=
%NODE% vsm_pack.mjs hulls_hi C19_51 >> %L% 2>&1
%NODE% vsm_pack.mjs hulls C19_51 >> %L% 2>&1
del /q hulls_hi\C19_51.vb hulls_hi\C19_51.ib hulls\C19_51.vb hulls\C19_51.ib 2>nul
"%PYEXE%" build.py test >> %L% 2>&1
if not exist shots_v54p mkdir shots_v54p
set OUT=shots_v54p
set TAG=v54p
set TPLS=c_boss
set ZOOM=1.0,0.6
"%PYEXE%" closeshot.py >> %L% 2>&1
set OUT=
set TAG=
set TPLS=
set ZOOM=
echo --- smoke --- >> %L%
"%PYEXE%" smoke.py >> %L% 2>&1
echo --- v54 test done --- >> %L%
cd /d "%~dp0"
