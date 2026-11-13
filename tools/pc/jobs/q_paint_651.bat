@echo off
rem Issue 651: queue the A18, A19 and A20 paint run (A18_A20_PAINT_651.bat) in its own minimised window, so the queue stays
rem free. The Board queues it.
start "paint 651" /min cmd /c "%USERPROFILE%\Downloads\voidsworn_test\A18_A20_PAINT_651.bat"
echo launched
exit /b 0
