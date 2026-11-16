@echo off
rem Issue 362: zip one opus362 output folder (copy, nothing deleted) so it can be pulled back in one file.
rem   zip362.bat FOLDER   writes opus362\zips\FOLDER.zip (a new name each call if it already exists)
setlocal
set "D=%USERPROFILE%\Downloads\voidsworn_test\opus362"
if not exist "%D%\zips" mkdir "%D%\zips"
set "Z=%D%\zips\%~1.zip"
if exist "%Z%" set "Z=%D%\zips\%~1_%RANDOM%.zip"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%D%\%~1\*' -DestinationPath '%Z%' -CompressionLevel Fastest"
echo %date% %time% zipped %~1 to %Z% exit %errorlevel% >> "%D%\status_zip.txt"
exit /b 0
