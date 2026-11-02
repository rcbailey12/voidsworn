@echo off
rem Voidsworn: start the test runner (watcher.bat) by itself whenever you log in to Windows.
set "S=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\voidsworn_watcher.bat"
> "%S%" echo @echo off
>> "%S%" echo start "Voidsworn test watcher" /min "%~dp0watcher.bat"
set "L=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\voidsworn_watcher_b.bat"
> "%L%" echo @echo off
>> "%L%" echo start "VS job queue B" /min "%~dp0watcher_b.bat"
if exist "%L%" (echo Done. The second test runner, which runs the Codex jobs, starts by itself too.)
set "C=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\voidsworn_codex_board.bat"
> "%C%" echo @echo off
>> "%C%" echo start "Voidsworn Codex board watcher" /min "%USERPROFILE%\Downloads\voidsworn_test\codex_board.bat"
if exist "%S%" (echo Done. The Voidsworn test runner now starts by itself when you log in.) else (echo Something went wrong: the startup file was not created.)
if exist "%C%" (echo Done. The Codex board watcher now starts by itself too.) else (echo Something went wrong: the Codex watcher startup file was not created.)
echo To undo this, double-click autostart_off.bat in the same folder.
pause
