@echo off
rem Board queue entry. Wait for the job and return its watchdog exit code.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
if not exist "%V%\E11_E12_PAINT_642.bat" exit /b 2
call "%V%\work217\tools\tmo.bat" 10800 "%ComSpec%" /d /s /c ""%V%\E11_E12_PAINT_642.bat""
exit /b %ERRORLEVEL%
