@echo off
rem Issue 1414 Harrow S11 (V15_37) round 2 fix (floats seated), frozen pin board/pin-1414c = f4867b996a7591f4f5897c427ca0d650b5c02316 (issue 1389).
set "SHIP=voidsworn_S11" & set "CODE=V15_37" & set "BRANCH=board/pin-1414c" & set "JOB_DIR=opus1414c"
set "STAGES=4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
