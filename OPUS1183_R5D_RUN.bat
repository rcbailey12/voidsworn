@echo off
rem Issue 1183 r5d: stage 7 only on the r5c bake, to prove the new exporter (emission map at 2048) and recapture camera 170.
set "SHIP=ithar_CD5" & set "CODE=I8_37" & set "BRANCH=opus/issue-1183" & set "JOB_DIR=opus1183r5d" & set "SETS=battle,close,cams" & set "STAGES=7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
