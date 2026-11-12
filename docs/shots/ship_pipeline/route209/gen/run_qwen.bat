@echo off
rem Opus #209: Qwen-Image-Edit pass (GPU, about 10 to 15 minutes). Log: opus209\gen\qwen.log
set V=%USERPROFILE%\Downloads\voidsworn_test
"%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe" -s "%V%\opus209\gen\gen209_qwen.py" "%V%\opus209\gen" > "%V%\opus209\gen\qwen.log" 2>&1
echo exit %errorlevel% >> "%V%\opus209\gen\qwen.log"
