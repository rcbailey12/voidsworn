@echo off
rem R431 rebuild of ithar_GV2 (ithar_GV2) through the shared Glasswright kit: pearl shell, glass only in the seams. All seven
rem stages, branch opus/issue-1777-glass (holds PR 1786, so the in-game shots are Ship Look V2). AFTER shots at camera
rem 170 and 26 (VS_A4_RADII). Not a publish: stage 7 installs into the job clone only.
set "VS_A4_RADII=170,26"
set "SHIP=ithar_GV2" & set "CODE=ithar_GV2" & set "BRANCH=opus/issue-1777-glass" & set "JOB_DIR=opus431_GV2"
set "SETS=close" & set "FACS=craft"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
set "VS_A4_RADII="
exit /b %ERRORLEVEL%
