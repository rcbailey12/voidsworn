@echo off
rem Board: frozen pin board/pin-1415f = b8c7097f29938e73a444a462e958f304ee7a7e7c (ship_job builds the branch tip, issue 1389).
set "SHIP=ithar_GS1" & set "CODE=I14_23" & set "BRANCH=board/pin-1415f" & set "JOB_DIR=opus1415f_GS1"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
