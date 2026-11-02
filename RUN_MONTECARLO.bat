@echo off
setlocal
cd /d "%~dp0"
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js is required. Install the free Node.js LTS version, then try again.
  pause
  exit /b 1
)
node "%~dp0contrib\opus\tools\run_montecarlo.js" %*
set "MC_EXIT=%ERRORLEVEL%"
echo.
pause
exit /b %MC_EXIT%
