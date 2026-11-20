@echo off
rem Issue 1154: queue the C13 recipe run (C13_RUN_1154.bat front) in its own minimised window.
start "c1154run" /min cmd /c "%USERPROFILE%\Downloads\voidsworn_test\opus1154\repo\tools\pc\jobs\C13_RUN_1154.bat front"
