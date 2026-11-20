@echo off
rem Board: frozen pin board/pin-1415 = 975f43329827af0bdd68ce84ee534d9eac273a7f (ship_job builds the branch tip, issue 1389).
set "SHIP=ithar_GS1" & set "CODE=I14_23" & set "BRANCH=board/pin-1415" & set "JOB_DIR=opus1415_GS1"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
