@echo off
rem Issue 1414 Harrow S11 (V15_37), frozen pin board/pin-1414 = 33a91350072261d33f966d69af2097349f2c1929 (ship_job builds the branch tip, issue 1389).
set "SHIP=voidsworn_S11" & set "CODE=V15_37" & set "BRANCH=board/pin-1414" & set "JOB_DIR=opus1414"
set "STAGES=4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
