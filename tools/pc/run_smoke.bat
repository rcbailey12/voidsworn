@echo off
REM Voidsworn PC runner: runs build\job.bat if present (one-off job), otherwise the full smoke test. Log: smoke_log.txt
cd /d "%~dp0"
if exist smoke_done.txt del smoke_done.txt
set /p PYEXE=<python_path.txt
set "PYTHONPATH=%~dp0"
set "PYTHONIOENCODING=utf-8"
set "PYTHONUTF8=1"
cd build
echo Run started %date% %time% > ..\smoke_log.txt
if exist job.bat (
  call job.bat
  del job.bat
) else (
  echo --- build --- >> ..\smoke_log.txt
  "%PYEXE%" build.py test >> ..\smoke_log.txt 2>&1
  echo --- smoke --- >> ..\smoke_log.txt
  "%PYEXE%" smoke.py >> ..\smoke_log.txt 2>&1
)
echo EXIT %errorlevel% >> ..\smoke_log.txt
echo Run finished %date% %time% >> ..\smoke_log.txt
cd ..
echo DONE > smoke_done.txt
