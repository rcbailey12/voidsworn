@echo off
rem Issue 633: queue the A18, A19 and A20 recipe run (A18_A20_RUN_633.bat) in its own minimised window. The Board queues it.
start "a633run" /min cmd /c "%USERPROFILE%\Downloads\voidsworn_test\A18_A20_RUN_633.bat"
