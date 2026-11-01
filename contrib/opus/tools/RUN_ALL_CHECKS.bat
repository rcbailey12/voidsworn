@echo off
setlocal
cd /d "%~dp0..\..\.."
node "%~dp0run_all_checks.js" %*
set "CHECK_EXIT=%ERRORLEVEL%"
echo.
pause
exit /b %CHECK_EXIT%
