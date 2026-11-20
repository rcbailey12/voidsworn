@echo off
rem Issue 1155 C14 (B22_11) round G, frozen pin board/pin-1155-c14 = 6ec5683b7644568b3d712176f86cf7e8e7938dda (ship_job builds the branch tip, issue 1389).
set "SHIP=chorus_C14" & set "CODE=B22_11" & set "BRANCH=board/pin-1155-c14" & set "JOB_DIR=opus1155c14g" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
