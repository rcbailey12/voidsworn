@echo off
rem Issue 1155 C14 (B22_11) run H, armour everywhere plus slit sacs (R374), frozen pin board/pin-1155-c14h = 625d3f2afae2941bca1913ce5ef39cb87e24efb4 (issue 1389).
set "SHIP=chorus_C14" & set "CODE=B22_11" & set "BRANCH=board/pin-1155-c14h" & set "JOB_DIR=opus1155c14h" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
