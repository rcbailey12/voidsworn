@echo off
cd /d %~dp0
title Voidsworn checks
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js was not found on this PC.
  echo The game build already uses Node, so it should be installed;
  echo if this message appears, reinstall Node from nodejs.org and try again.
  pause
  exit /b 1
)
node checks.js > checks_report.txt 2>&1
type checks_report.txt
echo.
echo Full report saved as checks_report.txt in this folder.
pause
