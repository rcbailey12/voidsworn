@echo off
rem Issue 1291 C10 (B16_23) run E, armour everywhere plus slit sacs (R374), frozen pin board/pin-1291-c10e = 8c8fc1813bce5d319456307f198a1ed63a14da99 (issue 1389).
set "SHIP=chorus_C10" & set "CODE=B16_23" & set "BRANCH=board/pin-1291-c10e" & set "JOB_DIR=opus1291c10e" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
