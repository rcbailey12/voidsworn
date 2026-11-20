@echo off
rem Opus 1239 pictures 2: start it in its own window once the GPU line reaches it.
if not exist "%USERPROFILE%\Downloads\voidsworn_test\opus1239" mkdir "%USERPROFILE%\Downloads\voidsworn_test\opus1239"
copy /y "%~dp0OPUS1239_PICS2.bat" "%USERPROFILE%\Downloads\voidsworn_test\opus1239\OPUS1239_PICS2.bat" >nul
start "Opus 1239 pictures 2: collapse pace and hand-off" cmd /c "%USERPROFILE%\Downloads\voidsworn_test\opus1239\OPUS1239_PICS2.bat"
exit /b
