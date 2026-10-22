@echo off
set L=..\smoke_log.txt
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set NODE="%USERPROFILE%\Downloads\voidsworn_test\node\node.exe"
set IO=%USERPROFILE%\Downloads\voidsworn_test\comfy_io\C19_51
set V=%IO%\mvC2\C19_51
set CONCEPT=%USERPROFILE%\Downloads\voidsworn_meshes\picks\flux11_C19_51_cut.png
echo --- v12c: brighter paint, bigger panel seams --- >> %L%
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
if not exist shots_v55e mkdir shots_v55e
set OUT=shots_v55e
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
type "%IO%\kit\shell_log.txt" | findstr /i /c:"shell faces" /c:"kit faces" /c:"Error" >> %L%
echo --- v12c done --- >> %L%
cd /d "%~dp0"
