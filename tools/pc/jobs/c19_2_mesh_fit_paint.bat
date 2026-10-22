@echo off
set L=..\smoke_log.txt
set BL="%USERPROFILE%\Downloads\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe"
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set IO=%USERPROFILE%\Downloads\voidsworn_test\comfy_io\C19_51
set PK=%USERPROFILE%\Downloads\voidsworn_meshes\picks
if not exist "%IO%\mvE1" mkdir "%IO%\mvE1"
if not exist "%IO%\mvE2" mkdir "%IO%\mvE2"
copy /y "%IO%\mvD\*.png" "%IO%\mvE1\" >nul
copy /y "%IO%\mvC\*.png" "%IO%\mvE2\" >nul
echo --- pixal3d E1 (sides + concept, max detail) --- >> %L%
%PY% -s comfy_run.py mesh C19_51 E1 left,right,concept "90,0;270,0;34,14" 2048 2000000 1536 1 >> %L% 2>&1
echo --- pixal3d E2 (sides + concept + front, max detail) --- >> %L%
%PY% -s comfy_run.py mesh C19_51 E2 left,right,concept,front "90,0;270,0;34,14;0,0" 2048 2000000 1536 1 >> %L% 2>&1
for %%T in (E1 E2) do call :finish %%T
echo --- E runs done --- >> %L%
cd /d "%~dp0"
goto :eof
:finish
set T=%1
set V=%IO%\mvC2\C19_51
if not exist "%IO%\mesh\C19_51%T%_pixal_tex_00001_.glb" (echo no mesh %T% >> %L% & goto :eof)
%BL% -b --factory-startup -P fitcam_render.py -- "%IO%\mesh\C19_51%T%_pixal_tex_00001_.glb" "%IO%\proj\sil%T%" -56 14 24 3 > "%IO%\proj\fit%T%_log.txt" 2>&1
%PY% -s fitcam_fit.py "%IO%\proj\sil%T%" "%PK%\flux11_C19_51_cut.png" "%IO%\proj\%T%_concept" >> "%IO%\proj\fit%T%_log.txt" 2>&1
set FR=
if "%T%"=="E2" set FR="%V%_front.png|%V%_front_mask.png|-90|0|0.8"
%BL% -b --factory-startup -P project_paint.py -- "%IO%\mesh\C19_51%T%_pixal_tex_00001_.glb" "%IO%\proj\%T%_albproj.png" 4096 "%V%_left.png|%V%_left_mask.png|0|0|1" "%V%_right.png|%V%_right_mask.png|180|0|1" "%IO%\proj\%T%_concept.png|%IO%\proj\%T%_concept_mask.png|@%IO%\proj\%T%_concept.json|0|1.2" %FR% > "%IO%\proj\proj%T%_log.txt" 2>&1
set ALB=%IO%\proj\%T%_albproj.png
%BL% -b --factory-startup -P render_multi.py -- "%IO%\mesh\C19_51%T%_pixal_tex_00001_.glb" "%IO%\proj\%T%P_" "146 14;90 4;90 85;180 8;240 25;30 -35;150 30" > "%IO%\proj\render%T%_log.txt" 2>&1
set ALB=
echo finished %T% >> %L%
goto :eof
