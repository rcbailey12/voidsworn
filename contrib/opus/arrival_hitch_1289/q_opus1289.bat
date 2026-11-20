@echo off
rem Opus worker 1289: start it in its own window once no frame-time job holds the GPU.
start "Opus 1289: arrival hitch, before and after" cmd /c "%USERPROFILE%\Downloads\voidsworn_test\opus1289\OPUS1289_RUN.bat"
exit /b
