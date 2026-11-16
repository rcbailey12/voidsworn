@echo off
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "PY369="
if exist "%VT%\python_path.txt" set /p PY369=<"%VT%\python_path.txt"
if not defined PY369 exit /b 2
call "%~dp0..\tmo.bat" 120 "%PY369%" "%~dp0planet369_sheets.py"
exit /b %ERRORLEVEL%
