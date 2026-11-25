@echo off
rem Board queue entry. Wait for the job and return its watchdog exit code.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
if not exist "%V%\A18_A20_RUN_633.bat" exit /b 2
call "%V%\work217\tools\tmo.bat" 10800 "%ComSpec%" /d /s /c ""%V%\A18_A20_RUN_633.bat""
exit /b %ERRORLEVEL%
