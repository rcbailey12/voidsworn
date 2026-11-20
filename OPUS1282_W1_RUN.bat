@echo off
rem Issue 1282: Glasswright warming round on CD5, all seven stages (the bake changed), then the battle, close and cams shots.
set "SHIP=ithar_CD5" & set "CODE=I8_37" & set "BRANCH=opus/issue-1282" & set "JOB_DIR=opus1282w1" & set "SETS=battle,close,cams"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
