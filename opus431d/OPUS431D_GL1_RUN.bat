@echo off
rem R431 round 3 (Ryan Nov 23 2026: every Glasswright reads as I8_37): rebuild of ithar_GL1 (I11_37) with the shared kit's
rem one-colour-per-leaf glass and I8_37 pearl shell (opus/issue-1777-glass at 3f016cb5 or later; the branch holds PR 1786, so the shots are Ship
rem Look V2). All seven stages, AFTER shots at camera 170 and 26 (VS_A4_RADII). Not a publish: stage 7 installs into the
rem job clone only. Pictures land in out\shots; OPUS431D_AFTER.bat copies them to a relayed folder afterwards.
set "VS_A4_RADII=170,26"
set "SHIP=ithar_GL1" & set "CODE=I11_37" & set "BRANCH=opus/issue-1777-glass" & set "JOB_DIR=opus431d_GL1"
set "SETS=cams" & set "FACS=ithar"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
set "VS_A4_RADII="
exit /b %ERRORLEVEL%
