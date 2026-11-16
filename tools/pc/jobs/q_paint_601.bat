@echo off
rem issue 601: start the A16 and A17 paint run in its own window, so the queue stays free
start "paint 601" /min cmd /c "%USERPROFILE%\Downloads\voidsworn_test\PAINT_RUN_601.bat"
echo launched
exit /b 0
