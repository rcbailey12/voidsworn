@echo off
REM Voidsworn lane B watcher: CPU-only jobs (downloads, parity, bot runs, sims). Runs queue_b\*.bat from build_b\.
REM Old way still works: drop run.request (runs build\job.bat through run_smoke.bat).
REM Queue: drop any NAME.bat into queue_b\ ; jobs run one at a time, oldest first, from build\ ;
REM output goes to queue_b\logs\NAME.log, and the job file moves to queue_b\done\ when finished.
cd /d "%~dp0"
title VS job queue B
if not exist queue_b mkdir queue_b
if not exist queue_b\done mkdir queue_b\done
if not exist queue_b\logs mkdir queue_b\logs
if not exist queue_b\running mkdir queue_b\running
echo Watching %cd% for run.request and queue_b\*.bat ... (close this window to stop)
:loop
cd /d "%~dp0"
cd /d "%~dp0"
set "J="
for /f "delims=" %%F in ('dir /b /od queue_b\*.bat 2^>nul') do if not defined J set "J=%%F"
if defined J (
  move /y "queue_b\%J%" "queue_b\running\%J%" >nul
  echo [%date% %time%] queue: %J% started
  echo [%date% %time%] started > "queue_b\logs\%J%.log"
  pushd build_b
  call "%~dp0queue_b\running\%J%" >> "%~dp0queue_b\logs\%J%.log" 2>&1
  popd
  cd /d "%~dp0"
  echo [%date% %time%] finished >> "queue_b\logs\%J%.log"
  move /y "queue_b\running\%J%" "queue_b\done\%J%" >nul
  echo [%date% %time%] queue: %J% finished
)
timeout /t 5 /nobreak >nul
goto loop
