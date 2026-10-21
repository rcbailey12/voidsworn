@echo off
REM Voidsworn test watcher: leave this window open. Drop run.request into this folder to start a smoke run.
cd /d "%~dp0"
title Voidsworn test watcher
echo Watching %cd% for run.request ... (close this window to stop)
:loop
if exist run.request (
  del run.request
  echo [%time%] Smoke run started
  call run_smoke.bat
  echo [%time%] Smoke run finished
)
timeout /t 5 /nobreak >nul
goto loop
