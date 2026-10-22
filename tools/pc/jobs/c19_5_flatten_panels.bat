@echo off
set L=..\smoke_log.txt
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set NODE="%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
set IO=%USERPROFILE%\Downloads\voidsworn_test\comfy_io\C19_51
set V=%IO%\mvC2\C19_51
set CONCEPT=%USERPROFILE%\Downloads\voidsworn_meshes\picks\flux11_C19_51_cut.png
echo --- v55b: gentle flatten of the wavy AI panels (60%%) --- >> %L%
%BL% -b --factory-startup -P panel_flatten.py -- "%IO%\kit\E2_cut.glb" "%IO%\kit\E2_cutf.glb" > "%IO%\kit\flat_log.txt" 2>&1
%BL% -b --factory-startup -P lod_make.py -- "%IO%\kit\E2_cutf.glb" "%IO%\kit\E2cutf" 250000 > "%IO%\kit\lodf_log.txt" 2>&1
set ALB=%IO%\proj\E2_albproj.png
set EXTRA=%IO%\kit\E2_kit_painted.glb
%BL% -b --factory-startup -P render_multi.py -- "%IO%\kit\E2_cutf.glb" "%IO%\kit\F11_" "146 14;90 4;90 85;180 8;240 25;150 30;120 12;160 22;20 20;90 -40;0 10" > "%IO%\kit\renderf_log.txt" 2>&1
set EXTRA=
set KIT=%IO%\kit\E2_kit_painted.glb
%PY% -s pixal_to_game.py "%IO%\kit\E2_cutf.glb" hulls_hi C19_51 left 4096 >> %L% 2>&1
%PY% -s pixal_to_game.py "%IO%\kit\E2cutf_250000.glb" hulls C19_51 left 2048 >> %L% 2>&1
set ALB=
set KIT=
%NODE% vsm_pack.mjs hulls_hi C19_51 >> %L% 2>&1
%NODE% vsm_pack.mjs hulls C19_51 >> %L% 2>&1
del /q hulls_hi\C19_51.vb hulls_hi\C19_51.ib hulls\C19_51.vb hulls\C19_51.ib 2>nul
"%PYEXE%" build.py test >> %L% 2>&1
if not exist shots_v55b mkdir shots_v55b
set OUT=shots_v55b
set TPLS=c_boss
set ZOOM=1.0,0.5
set MAP=belt
set TAG=belt
"%PYEXE%" closeshot.py >> %L% 2>&1
set MAP=
set OUT=
set TAG=
set TPLS=
set ZOOM=
type "%IO%\kit\flat_log.txt" | findstr /c:"wavy plates" /c:"moved" >> %L%
echo --- v55b done --- >> %L%
cd /d "%~dp0"
