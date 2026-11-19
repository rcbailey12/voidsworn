@echo off
rem Issue 1155: queue the C14 recipe run (C14_RUN_1155.bat front) in its own minimised window.
start "c1155run" /min cmd /c "%USERPROFILE%\Downloads\voidsworn_test\opus1155\repo\tools\pc\jobs\C14_RUN_1155.bat front"
