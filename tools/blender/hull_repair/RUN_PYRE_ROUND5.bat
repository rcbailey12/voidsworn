@echo off
setlocal
set "PY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
"%PY%" -s -B "%~dp0round5_run.py" %*
if errorlevel 1 echo The job could not be queued. Read the message above.
echo Review sheets: %USERPROFILE%\Downloads\voidsworn_test\board\issue-163\shots
if "%~1"=="" pause
