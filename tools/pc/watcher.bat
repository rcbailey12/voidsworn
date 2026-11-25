@echo off
setlocal EnableExtensions DisableDelayedExpansion
REM Voidsworn test watcher with a job queue: leave this window open.
REM Old way still works: drop run.request (runs build\job.bat through run_smoke.bat).
REM Queue: drop any NAME.bat into queue\ ; jobs run one at a time, oldest first, from build\ ;
REM output goes to queue\logs\NAME.log with its exit code, and the job file moves to queue\done\ when it exits 0 or to
REM queue\failed\ when it exits with any other code (issue 1194).
cd /d "%~dp0"
title VS job queue
if exist watcher_b.bat start "" /min "%~dp0watcher_b.bat"
if not exist queue mkdir queue
if not exist queue\done mkdir queue\done
if not exist queue\failed mkdir queue\failed
if not exist queue\logs mkdir queue\logs
if not exist queue\running mkdir queue\running
rem Only one watcher can open this queue lock for writing. The handle stays open for the loop.
(call :watch) 9>"%~dp0queue\watcher.lock" || echo WARNING: could not lock queue\watcher.lock. Another watcher may be running.
exit /b
:watch
schtasks /query /tn "Voidsworn Janitor" >nul 2>&1 || echo WARNING: Voidsworn Janitor task missing or unreadable. Run janitor_task.bat from the current tools_live pc folder.
set "OX_MINUTE="
echo Watching %cd% for run.request and queue\*.bat ... (close this window to stop)
:loop
cd /d "%~dp0"
findstr /b /c:"GPU not cleared: paused by the Board" gpu_go.txt >nul 2>&1 && goto idle_wait
if exist run.request (
  del run.request
  echo [%time%] Smoke run started
  call run_smoke.bat
  echo [%time%] Smoke run finished
)
cd /d "%~dp0"
set "J="
for /f "delims=" %%F in ('dir /b /od queue\*.bat 2^>nul') do if not defined J if not exist "queue\running\%%F" set "J=%%F"
if not defined J goto idle
rem (1194) Between jobs, refresh the main queue's build\tools and the canonical tools_live copy that every tmo.bat uses.
rem A busy or failed refresh keeps the copies it has; the log says why. Nothing here deletes a job's work.
set "RF=%~dp0lane_tools_refresh.ps1"
set "TLV="
if exist "tools_live\current.txt" set /p TLV=<"tools_live\current.txt"
if defined TLV if exist "tools_live\%TLV%\pc\lane_tools_refresh.ps1" set "RF=%~dp0tools_live\%TLV%\pc\lane_tools_refresh.ps1"
if exist "%RF%" powershell -NoProfile -ExecutionPolicy Bypass -File "%RF%" -Build tools_live >> "queue\logs\tools_refresh.txt" 2>&1
if exist "%RF%" powershell -NoProfile -ExecutionPolicy Bypass -File "%RF%" -Build build >> "queue\logs\tools_refresh.txt" 2>&1
cd /d "%~dp0"
findstr /b /c:"GPU not cleared: paused by the Board" gpu_go.txt >nul 2>&1 && goto idle_wait
rem Keep an older interrupted job, and never run a file this watcher did not claim.
if exist "queue\running\%J%" goto idle
move /y "queue\%J%" "queue\running\%J%" >nul 2>&1 || goto idle
echo [%date% %time%] queue: %J% started
echo [%date% %time%] started > "queue\logs\%J%.log"
set "JX=1"
pushd build || goto file_result
"%ComSpec%" /d /c call "%~dp0queue\running\%J%" >> "%~dp0queue\logs\%J%.log" 2>&1
set "JX=%ERRORLEVEL%"
popd
:file_result
cd /d "%~dp0"
rem (1194) The exit code decides where the job file goes: 0 to queue\done, anything else to queue\failed.
echo [%date% %time%] finished, exit %JX% >> "queue\logs\%J%.log"
if "%JX%"=="0" (move /y "queue\running\%J%" "queue\done\%J%" >nul) else (move /y "queue\running\%J%" "queue\failed\%J%" >nul)
if "%JX%"=="0" (echo [%date% %time%] queue: %J% finished) else (echo [%date% %time%] queue: %J% FAILED, exit %JX%, moved to queue\failed)
:idle
rem (1663) Overnight, about every 10 minutes while the queue is idle, tools_live's overnight_export.ps1 decides whether to
rem queue one build\export refresh (its gates: 1 to 5 AM Central, gpu_go clear, 75 GB free, nothing running, main changed
rem game files). It only ever adds a queue job; it deletes nothing.
if "%OX_MINUTE%"=="%time:~0,4%" goto idle_wait
set "OX_MINUTE=%time:~0,4%"
set "TLV="
if exist "tools_live\current.txt" set /p TLV=<"tools_live\current.txt"
if defined TLV if exist "tools_live\%TLV%\pc\overnight_export.ps1" powershell -NoProfile -ExecutionPolicy Bypass -File "tools_live\%TLV%\pc\overnight_export.ps1" >> "queue\logs\overnight_export.txt" 2>&1
:idle_wait
timeout /t 5 /nobreak >nul
goto loop
