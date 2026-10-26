@echo off
rem Voidsworn: stop the test runner from starting by itself at login.
set "S=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\voidsworn_watcher.bat"
if exist "%S%" (del "%S%" & echo Done. The test runner no longer starts by itself.) else (echo It was already off.)
pause
