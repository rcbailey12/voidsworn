@echo off
setlocal
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js is required. No checks ran.
  pause
  exit /b 2
)
if "%~1"=="" (
  node "%~dp0tools\run_checks.js"
) else (
  node "%~dp0tools\run_checks.js" --godot "%~1"
)
set "VOIDSWORN_CHECK_EXIT=%ERRORLEVEL%"
echo.
if not "%VOIDSWORN_CHECK_EXIT%"=="0" echo Checks are incomplete or failed. Read the result above.
pause
exit /b %VOIDSWORN_CHECK_EXIT%
