@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_qa.ps1" -SelfTest
set "VOIDSWORN_QA_EXIT=%ERRORLEVEL%"
pause
exit /b %VOIDSWORN_QA_EXIT%
