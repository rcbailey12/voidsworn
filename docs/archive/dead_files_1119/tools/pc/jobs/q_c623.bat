@echo off
rem Issue 623: queue the C10 and C11 recipe run (C10_C11_RUN_623.bat) in its own minimised window. The Board queues it.
start "c623run" /min cmd /c "%USERPROFILE%\Downloads\voidsworn_test\C10_C11_RUN_623.bat"
