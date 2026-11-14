@echo off
rem Issue 642: queue the E11 and E12 paint run (E11_E12_PAINT_642.bat) in its own minimised window, so the queue stays free.
rem The Board queues it.
start "paint 642" /min cmd /c "%USERPROFILE%\Downloads\voidsworn_test\E11_E12_PAINT_642.bat"
echo launched
exit /b 0
