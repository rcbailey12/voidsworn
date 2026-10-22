@echo off
set L=..\smoke_log.txt
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
copy /y voidsworn_pixal_views.py "%USERPROFILE%\Downloads\ComfyUI_windows_portable\ComfyUI\custom_nodes\" >> %L% 2>&1
echo --- comfy views pass 2 C19_51 --- >> %L%
%PY% -s comfy_run.py views C19_51 2 "front;back;front_lo=front view low-angle shot medium shot;back_lo=back view low-angle shot medium shot" "%USERPROFILE%\Downloads\voidsworn_test\comfy_io\C19_51\views\C19_51_right_s1_00001_.png" _b >> %L% 2>&1
echo --- comfy views pass 2 done --- >> %L%
cd /d "%~dp0"
