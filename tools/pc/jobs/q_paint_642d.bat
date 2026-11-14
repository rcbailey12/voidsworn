@echo off
rem Board queues this once. Keep the queue occupied until the GPU job ends; the watchdog waits while Ryan plays.
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
call "%V%\work217\tools\tmo.bat" 10800 cmd.exe /d /c ""%V%\E11_E12_PAINT_642d.bat""
exit /b %ERRORLEVEL%
