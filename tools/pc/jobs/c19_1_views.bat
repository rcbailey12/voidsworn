@echo off
set L=..\smoke_log.txt
echo --- comfy views C19_51 --- >> %L%
"%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe" -s comfy_run.py views C19_51 2 >> %L% 2>&1
echo --- comfy views done --- >> %L%
cd /d "%~dp0"
