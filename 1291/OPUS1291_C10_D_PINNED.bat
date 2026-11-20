@echo off
rem Issue 1291 C10 (B16_23) run D, armour everywhere (R374), frozen pin board/pin-1291-c10d = 0da41226e16776166d8fa09e6bee1075e36dce99 (ship_job builds the branch tip, issue 1389).
set "SHIP=chorus_C10" & set "CODE=B16_23" & set "BRANCH=board/pin-1291-c10d" & set "JOB_DIR=opus1291c10d" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
