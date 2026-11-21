@echo off
rem issue 651: start the A18, A19 and A20 paint run in its own window, so the queue stays free
start "paint 651" /min cmd /c "%USERPROFILE%\Downloads\voidsworn_test\A18_A20_PAINT_651.bat"
echo launched
exit /b 0
