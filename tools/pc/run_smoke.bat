@echo off
REM Voidsworn PC runner: runs build\job.bat if present (one-off job), otherwise the full smoke test. Log: smoke_log.txt
REM Issue 1194: each step runs through job_wrap.bat from the installed main tools (tools_live). smoke_done.txt and
REM EXIT in smoke_log.txt now say PASS or FAILED: <step>, and the exit code is 0 only on PASS. Nothing is deleted except
REM build\job.bat after it ran (as before) and the previous smoke_done.txt (moved to smoke_done_previous.txt).
setlocal EnableExtensions
cd /d "%~dp0"
if exist smoke_done.txt move /y smoke_done.txt smoke_done_previous.txt > nul
set /p PYEXE=<python_path.txt
set "PYTHONPATH=%~dp0"
set "PYTHONIOENCODING=utf-8"
set "PYTHONUTF8=1"
set "JW="
set "TLV="
if exist "tools_live\current.txt" set /p TLV=<"tools_live\current.txt"
if defined TLV if exist "tools_live\%TLV%\pc\job_wrap.bat" set "JW=%~dp0tools_live\%TLV%\pc\job_wrap.bat"
if not defined JW if exist "build\tools\pc\job_wrap.bat" set "JW=%~dp0build\tools\pc\job_wrap.bat"
echo Run started %date% %time% > smoke_log.txt
if defined JW goto wrapped
echo FAILED: no job_wrap.bat in tools_live or build\tools >> smoke_log.txt
echo EXIT 1 >> smoke_log.txt
> smoke_done.txt echo FAILED: no job_wrap.bat
endlocal & exit /b 1
:wrapped
if not defined PC_GPU_ISSUE set "PC_GPU_ISSUE=run_smoke"
call "%JW%" init "%~dp0smoke" "%PC_GPU_ISSUE%" ""
set "SX=%ERRORLEVEL%"
if not "%SX%"=="0" goto report
cd build
if exist job.bat (
  set "JW_STEP=build job.bat" & call "%JW%" run 21600 "%ComSpec%" /d /c job.bat >> ..\smoke_log.txt 2>&1
  del job.bat
) else (
  echo --- build --- >> ..\smoke_log.txt
  set "JW_STEP=build.py test" & call "%JW%" run 3600 "%PYEXE%" build.py test >> ..\smoke_log.txt 2>&1
  echo --- smoke --- >> ..\smoke_log.txt
  set "JW_STEP=smoke.py" & call "%JW%" run 3600 "%PYEXE%" smoke.py >> ..\smoke_log.txt 2>&1
)
cd ..
call "%JW%" end
set "SX=%ERRORLEVEL%"
:report
echo EXIT %SX% >> smoke_log.txt
echo Run finished %date% %time% >> smoke_log.txt
copy /y "smoke\done.txt" smoke_done.txt > nul
endlocal & exit /b %SX%
