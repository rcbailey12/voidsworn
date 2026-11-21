@echo off
rem Issue 1413: rebake the Navy bomber with the round 3 Navy kit (grain and stronger plating seams).
set "SHIP=hegemony_HB1" & set "CODE=hegemony_HB1" & set "BRANCH=board/pin-1413e" & set "JOB_DIR=opus1413hb1e" & set "SETS=close"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
