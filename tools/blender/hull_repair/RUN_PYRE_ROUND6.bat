@echo off
setlocal
set "PY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
"%PY%" -s -B "%~dp0round6_run.py" %*
if errorlevel 1 echo The job could not be queued. Read the message above.
echo Review sheets: %USERPROFILE%\Downloads\voidsworn_test\board\issue-187\shots
if "%~1"=="" pause
