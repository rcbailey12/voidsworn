@echo off
setlocal
rem Free installed local tools only. Queues the owner's GPU lane A.
set "PY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
"%PY%" -s -B "%~dp0round4_run.py" %*
if errorlevel 1 echo The job could not be queued. Read the message above.
echo Review sheets: %USERPROFILE%\Downloads\voidsworn_test\board\issue-146\shots
if "%~1"=="" pause
