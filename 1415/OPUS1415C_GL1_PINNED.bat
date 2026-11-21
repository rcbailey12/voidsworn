@echo off
rem Board: frozen pin board/pin-1415c = aae93e7160a9886c534d4801c8cd11e0b3cc75a5 (ship_job builds the branch tip, issue 1389).
set "SHIP=ithar_GL1" & set "CODE=I11_37" & set "BRANCH=board/pin-1415c" & set "JOB_DIR=opus1415c_GL1"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
