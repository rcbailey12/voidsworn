@echo off
rem Issue 1683 (R411 P2d): rebuild chorus_C11 (B21_11) on the Chorus stack with the recess glow (PR 1703). No publish.
set "SHIP=chorus_C11" & set "CODE=B21_11" & set "BRANCH=board/pin-1683a" & set "JOB_DIR=opus1683c11"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
