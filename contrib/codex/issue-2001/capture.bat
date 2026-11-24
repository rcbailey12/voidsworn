@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0capture.ps1" %*
set "RESULT=%ERRORLEVEL%"
if not "%RESULT%"=="0" echo Material Maker comparison failed. See the message above.
if not defined JW_STEP if not defined VS_MM_NO_PAUSE pause
exit /b %RESULT%
