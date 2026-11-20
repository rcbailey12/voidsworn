@echo off
rem Issue 642 run c: queue the E11 and E12 paint run (E11_E12_PAINT_642c.bat) in its own minimised window, so the queue stays free.
rem The Board queues it. Runs 642 and 642b crashed in stage 5 on Blender 4.5; see the note in E11_E12_PAINT_642c.bat.
start "paint 642c" /min cmd /c "%USERPROFILE%\Downloads\voidsworn_test\E11_E12_PAINT_642c.bat"
echo launched
exit /b 0
