@echo off
rem Double-click. Lists the old board copies and idle helper folders on CLEAN_1180_ONEOFF2_list.txt with size, date and
rem issue, then deletes exactly those only if you type YES. Anything else stops with nothing removed.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CLEAN_1180_ONEOFF2.ps1"
pause
