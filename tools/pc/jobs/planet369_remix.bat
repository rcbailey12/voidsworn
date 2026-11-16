@echo off
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "PY369="
if exist "%VT%\python_path.txt" set /p PY369=<"%VT%\python_path.txt"
if not defined PY369 exit /b 2
call "%~dp0..\tmo.bat" 1200 "%PY369%" "%~dp0planet369_remix.py" %*
if errorlevel 1 exit /b 1
call "%~dp0planet369_pack.bat"
exit /b %ERRORLEVEL%
