@echo off
rem Voidsworn: start the test runner (watcher.bat) by itself whenever you log in to Windows.
set "S=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\voidsworn_watcher.bat"
> "%S%" echo @echo off
>> "%S%" echo start "Voidsworn test watcher" /min "%~dp0watcher.bat"
if exist "%S%" (echo Done. The Voidsworn test runner now starts by itself when you log in.) else (echo Something went wrong: the startup file was not created.)
echo To undo this, double-click autostart_off.bat in the same folder.
pause
