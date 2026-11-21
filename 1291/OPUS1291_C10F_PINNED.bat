@echo off
rem Board: frozen pin board/pin-1291-holes = 8dd88341aa40ccaa045d8d56af56d6949cd61ed1 (ship_job builds the branch tip, issue 1389).
set "SHIP=chorus_C10" & set "CODE=B16_23" & set "BRANCH=board/pin-1291-holes" & set "JOB_DIR=opus1291c10f" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
