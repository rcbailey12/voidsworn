@echo off
rem Double-click once from the installed tools to set up the nightly janitor.
setlocal
call "%~dp0janitor.bat" --install-task %*
set "JANITOR_TASK_EXIT=%ERRORLEVEL%"
if "%~1"=="" pause
exit /b %JANITOR_TASK_EXIT%
