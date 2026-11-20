@echo off
rem Issue 1414 Harrow S11 (V15_37) round 2 (tube cowls, slit vents), frozen pin board/pin-1414b = 05ef902a0e497c0530d41dde581f75db349be5ca (ship_job builds the branch tip, issue 1389).
set "SHIP=voidsworn_S11" & set "CODE=V15_37" & set "BRANCH=board/pin-1414b" & set "JOB_DIR=opus1414b"
set "STAGES=4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
