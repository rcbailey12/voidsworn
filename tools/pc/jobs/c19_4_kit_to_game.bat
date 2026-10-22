@echo off
set L=..\smoke_log.txt
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set NODE="%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
set IO=%USERPROFILE%\Downloads\voidsworn_test\comfy_io\C19_51
set V=%IO%\mvC2\C19_51
set CONCEPT=%USERPROFILE%\Downloads\voidsworn_meshes\picks\flux11_C19_51_cut.png
echo --- kit v6: side blocks, front plates, thrusters, stern house + bulkhead, tanks, old guns cleared --- >> %L%
%BL% -b --factory-startup -P c19_kit.py -- "%IO%\mesh\C19_51E2_pixal_tex_00001_.glb" "%IO%\kit\E2" > "%IO%\kit\kit_log.txt" 2>&1
%BL% -b --factory-startup -P lod_make.py -- "%IO%\kit\E2_cut.glb" "%IO%\kit\E2cut" 250000 > "%IO%\kit\lod_log.txt" 2>&1
set OCC=%IO%\kit\E2_cut.glb
set EXPORT=%IO%\kit\E2_kit_painted.glb
set "KEEP=0.125,0.305,-0.095,0.095,0.03,0.2"
%BL% -b --factory-startup -P project_paint.py -- "%IO%\kit\E2_kit.glb" "%IO%\kit\kit_albproj.png" 4096 "%V%_left.png|%V%_left_mask.png|0|0|1" "%V%_right.png|%V%_right_mask.png|180|0|1" "%IO%\proj\E2_concept.png|%IO%\proj\E2_concept_mask.png|@%IO%\proj\E2_concept.json|0|1.2" "%V%_front.png|%V%_front_mask.png|-90|0|0.8" > "%IO%\kit\kitproj_log.txt" 2>&1
set OCC=
set EXPORT=
set KEEP=
set ALB=%IO%\proj\E2_albproj.png
set EXTRA=%IO%\kit\E2_kit_painted.glb
%BL% -b --factory-startup -P render_multi.py -- "%IO%\kit\E2_cut.glb" "%IO%\kit\K6_" "146 14;90 4;90 85;180 8;240 25;150 30;120 12;160 22;20 20;90 -40;0 10" > "%IO%\kit\render_log.txt" 2>&1
set EXTRA=
set KIT=%IO%\kit\E2_kit_painted.glb
%PY% -s pixal_to_game.py "%IO%\kit\E2_cut.glb" hulls_hi C19_51 left 4096 >> %L% 2>&1
%PY% -s pixal_to_game.py "%IO%\kit\E2cut_250000.glb" hulls C19_51 left 2048 >> %L% 2>&1
set ALB=
set KIT=
%NODE% vsm_pack.mjs hulls_hi C19_51 >> %L% 2>&1
%NODE% vsm_pack.mjs hulls C19_51 >> %L% 2>&1
del /q hulls_hi\C19_51.vb hulls_hi\C19_51.ib hulls\C19_51.vb hulls\C19_51.ib 2>nul
"%PYEXE%" build.py test >> %L% 2>&1
if not exist shots_v54u mkdir shots_v54u
set OUT=shots_v54u
set TPLS=c_boss
set ZOOM=1.0,0.5
set MAP=belt
set TAG=belt
"%PYEXE%" closeshot.py >> %L% 2>&1
set MAP=planet
set TAG=planet
"%PYEXE%" closeshot.py >> %L% 2>&1
set ONLY=
set MAP=
set OUT=
set TAG=
set TPLS=
set ZOOM=
echo --- kit v6 done --- >> %L%
cd /d "%~dp0"
