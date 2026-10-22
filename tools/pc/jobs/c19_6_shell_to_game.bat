@echo off
set L=..\smoke_log.txt
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set NODE="%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
set IO=%USERPROFILE%\Downloads\voidsworn_test\comfy_io\C19_51
set V=%IO%\mvC2\C19_51
set CONCEPT=%USERPROFILE%\Downloads\voidsworn_meshes\picks\flux11_C19_51_cut.png
echo --- v13b: UV packing fix + detail pass (plating, repairs, pipes, vents, dents, Corsair jank) --- >> %L%
set SHELL=1
%BL% -b --factory-startup -P c19_kit.py -- "%IO%\mesh\C19_51E2_pixal_tex_00001_.glb" "%IO%\kit\S" > "%IO%\kit\shell_log.txt" 2>&1
set SHELL=
set PAINT=proc
set OCC=%IO%\kit\S_kit.glb
set EXPORT=%IO%\kit\S_shell_painted.glb
%BL% -b --factory-startup -P project_paint.py -- "%IO%\kit\S_shell.glb" "%IO%\kit\shell_albproj.png" 4096 > "%IO%\kit\shellproj_log.txt" 2>&1
set OCC=%IO%\kit\S_shell.glb
set EXPORT=%IO%\kit\S_kit_painted.glb
set "KEEP=0.125,0.305,-0.095,0.095,0.03,0.2;-0.1,0.055,-0.06,0.06,0.104,0.25"
%BL% -b --factory-startup -P project_paint.py -- "%IO%\kit\S_kit.glb" "%IO%\kit\skit_albproj.png" 4096 > "%IO%\kit\skitproj_log.txt" 2>&1
set OCC=
set EXPORT=
set KEEP=
set PAINT=
set EXTRA=%IO%\kit\S_kit_painted.glb
%BL% -b --factory-startup -P render_multi.py -- "%IO%\kit\S_shell_painted.glb" "%IO%\kit\K13b_" "146 14;90 4;90 85;180 8;240 25;150 30;120 12;160 22;20 20;90 -40;0 10;150 22" > "%IO%\kit\render12_log.txt" 2>&1
set EXTRA=
set PAINTK=1.0
set KIT=%IO%\kit\S_kit_painted.glb
%PY% -s pixal_to_game.py "%IO%\kit\S_shell_painted.glb" hulls_hi C19_51 left 4096 >> %L% 2>&1
%PY% -s pixal_to_game.py "%IO%\kit\S_shell_painted.glb" hulls C19_51 left 2048 >> %L% 2>&1
set KIT=
set PAINTK=
%NODE% vsm_pack.mjs hulls_hi C19_51 >> %L% 2>&1
%NODE% vsm_pack.mjs hulls C19_51 >> %L% 2>&1
del /q hulls_hi\C19_51.vb hulls_hi\C19_51.ib hulls\C19_51.vb hulls\C19_51.ib hulls_hi\C19_51_n.webp hulls_hi\C19_51_m.webp hulls\C19_51_n.webp hulls\C19_51_m.webp 2>nul
"%PYEXE%" build.py test >> %L% 2>&1
if not exist shots_v55g mkdir shots_v55g
set OUT=shots_v55g
set TPLS=c_boss
set ZOOM=1.0,0.5
set MAP=belt
set TAG=belt
"%PYEXE%" closeshot.py >> %L% 2>&1
set MAP=planet
set TAG=planet
"%PYEXE%" closeshot.py >> %L% 2>&1
set MAP=
set OUT=
set TAG=
set TPLS=
set ZOOM=
type "%IO%\kit\shell_log.txt" | findstr /i /c:"shell faces" /c:"kit faces" /c:"detail pass" /c:"dents" /c:"Error" >> %L%
echo --- v13b done --- >> %L%
cd /d "%~dp0"
