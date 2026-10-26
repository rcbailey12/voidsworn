@echo off
REM Voidsworn test watcher with a job queue: leave this window open.
REM Old way still works: drop run.request (runs build\job.bat through run_smoke.bat).
REM Queue: drop any NAME.bat into queue\ ; jobs run one at a time, oldest first, from build\ ;
REM output goes to queue\logs\NAME.log, and the job file moves to queue\done\ when finished.
cd /d "%~dp0"
title VS job queue
if exist watcher_b.bat start "" /min "%~dp0watcher_b.bat"
if not exist queue mkdir queue
if not exist queue\done mkdir queue\done
if not exist queue\logs mkdir queue\logs
if not exist queue\running mkdir queue\running
echo Watching %cd% for run.request and queue\*.bat ... (close this window to stop)
:loop
cd /d "%~dp0"
if exist run.request (
  del run.request
  echo [%time%] Smoke run started
  call run_smoke.bat
  echo [%time%] Smoke run finished
)
cd /d "%~dp0"
set "J="
for /f "delims=" %%F in ('dir /b /od queue\*.bat 2^>nul') do if not defined J set "J=%%F"
if defined J (
  move /y "queue\%J%" "queue\running\%J%" >nul
  echo [%date% %time%] queue: %J% started
  echo [%date% %time%] started > "queue\logs\%J%.log"
  pushd build
  call "%~dp0queue\running\%J%" >> "%~dp0queue\logs\%J%.log" 2>&1
  popd
  cd /d "%~dp0"
  echo [%date% %time%] finished >> "queue\logs\%J%.log"
  move /y "queue\running\%J%" "queue\done\%J%" >nul
  echo [%date% %time%] queue: %J% finished
)
timeout /t 5 /nobreak >nul
goto loop
