@echo off
REM Voidsworn lane B watcher: CPU-only jobs (downloads, parity, bot runs, sims). Runs queue_b\*.bat from build_b\.
REM Old way still works: drop run.request (runs build\job.bat through run_smoke.bat).
REM Queue: drop any NAME.bat into queue_b\ ; jobs run one at a time, oldest first, from build\ ;
REM output goes to queue_b\logs\NAME.log with its exit code, and the job file moves to queue_b\done\ when it exits 0 or
REM to queue_b\failed\ when it exits with any other code (issue 1194).
cd /d "%~dp0"
title VS job queue B
if not exist queue_b mkdir queue_b
if not exist queue_b\done mkdir queue_b\done
if not exist queue_b\failed mkdir queue_b\failed
if not exist queue_b\logs mkdir queue_b\logs
if not exist queue_b\running mkdir queue_b\running
echo Watching %cd% for run.request and queue_b\*.bat ... (close this window to stop)
:loop
cd /d "%~dp0"
cd /d "%~dp0"
set "J="
for /f "delims=" %%F in ('dir /b /od queue_b\*.bat 2^>nul') do if not defined J set "J=%%F"
if not defined J goto idle
move /y "queue_b\%J%" "queue_b\running\%J%" >nul
echo [%date% %time%] queue: %J% started
echo [%date% %time%] started > "queue_b\logs\%J%.log"
pushd build_b
call "%~dp0queue_b\running\%J%" >> "%~dp0queue_b\logs\%J%.log" 2>&1
set "JX=%ERRORLEVEL%"
popd
cd /d "%~dp0"
rem (1194) The exit code decides where the job file goes: 0 to queue_b\done, anything else to queue_b\failed.
echo [%date% %time%] finished, exit %JX% >> "queue_b\logs\%J%.log"
if "%JX%"=="0" (move /y "queue_b\running\%J%" "queue_b\done\%J%" >nul) else (move /y "queue_b\running\%J%" "queue_b\failed\%J%" >nul)
if "%JX%"=="0" (echo [%date% %time%] queue: %J% finished) else (echo [%date% %time%] queue: %J% FAILED, exit %JX%, moved to queue_b\failed)
:idle
timeout /t 5 /nobreak >nul
goto loop
