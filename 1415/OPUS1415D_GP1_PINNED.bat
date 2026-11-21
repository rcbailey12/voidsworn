@echo off
rem Board: frozen pin board/pin-1415d = a76a10cc8c4296e809c41643fcd0b0c8531f8152 (ship_job builds the branch tip, issue 1389).
set "SHIP=ithar_GP1" & set "CODE=I15_11" & set "BRANCH=board/pin-1415d" & set "JOB_DIR=opus1415d_GP1"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
