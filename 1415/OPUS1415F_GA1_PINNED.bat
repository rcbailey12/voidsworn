@echo off
rem Board: frozen pin board/pin-1415f = b8c7097f29938e73a444a462e958f304ee7a7e7c (ship_job builds the branch tip, issue 1389).
set "SHIP=ithar_GA1" & set "CODE=I16_11" & set "BRANCH=board/pin-1415f" & set "JOB_DIR=opus1415f_GA1"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
