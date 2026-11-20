@echo off
rem Board: frozen pin board/pin-1415b = 3bcb35f24dd3a6abbc8786a1c4b2b6afc67b6c01 (ship_job builds the branch tip, issue 1389).
set "SHIP=ithar_GS1" & set "CODE=I14_23" & set "BRANCH=board/pin-1415b" & set "JOB_DIR=opus1415_GS1"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
