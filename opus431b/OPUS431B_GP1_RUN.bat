@echo off
rem R431 round 2 (Ryan Nov 23 2026: every Glasswright reads as I8_37): rebuild of ithar_GP1 (I15_11) with the shared kit's
rem one-colour-per-leaf glass (opus/issue-1777-glass at 49c8d4b0 or later; the branch holds PR 1786, so the shots are Ship
rem Look V2). All seven stages, AFTER shots at camera 170 and 26 (VS_A4_RADII). Not a publish: stage 7 installs into the
rem job clone only. Pictures land in out\shots; OPUS431B_AFTER.bat copies them to a relayed folder afterwards.
set "VS_A4_RADII=170,26"
set "SHIP=ithar_GP1" & set "CODE=I15_11" & set "BRANCH=opus/issue-1777-glass" & set "JOB_DIR=opus431b_GP1"
set "SETS=cams" & set "FACS=ithar"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
set "VS_A4_RADII="
exit /b %ERRORLEVEL%
