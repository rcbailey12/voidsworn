@echo off
rem Opus worker 1279 run 3C: start it in its own window once no frame-time job holds the GPU.
if not exist "%USERPROFILE%\Downloads\voidsworn_test\opus1279" mkdir "%USERPROFILE%\Downloads\voidsworn_test\opus1279"
copy /y "%~dp0OPUS1279_RUN3C.bat" "%USERPROFILE%\Downloads\voidsworn_test\opus1279\OPUS1279_RUN3C.bat" >nul
start "Opus 1279 run 3C: Jolt overflow before and after" cmd /c "%USERPROFILE%\Downloads\voidsworn_test\opus1279\OPUS1279_RUN3C.bat"
exit /b
