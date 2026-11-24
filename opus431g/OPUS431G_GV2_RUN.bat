@echo off
rem R431 round G (Ryan Nov 24 2026: craft on the big-ship shell, bomber drive, destroyer torpedo on the spine): rebuild of ithar_GV2 (ithar_GV2) with the shared kit's
rem one-colour-per-leaf glass and I8_37 pearl shell (opus/issue-1777-glass at 5472ca27 or later; the branch holds PR 1786, so the shots are Ship
rem Look V2). All seven stages, AFTER shots at camera 170 and 26 (VS_A4_RADII). Not a publish: stage 7 installs into the
rem job clone only. Pictures land in out\shots; OPUS431G_AFTER.bat copies them to a relayed folder afterwards.
set "VS_A4_RADII=170,26"
set "SHIP=ithar_GV2" & set "CODE=ithar_GV2" & set "BRANCH=opus/issue-1777-glass" & set "JOB_DIR=opus431g_GV2"
set "SETS=close" & set "FACS=craft"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
set "VS_A4_RADII="
exit /b %ERRORLEVEL%
