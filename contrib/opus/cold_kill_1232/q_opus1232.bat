@echo off
rem Opus worker 1232: start it in its own window once no frame-time job holds the GPU.
start "Opus 1232: first kill timing" cmd /c "%USERPROFILE%\Downloads\voidsworn_test\opus1232\OPUS1232_RUN.bat"
exit /b
