@echo off
rem Issue 1153: queue the C12 recipe run (C12_RUN_1153.bat, stages 1 to 4 by default) in its own minimised window.
start "c1153run" /min cmd /c "%USERPROFILE%\Downloads\voidsworn_test\C12_RUN_1153.bat"
