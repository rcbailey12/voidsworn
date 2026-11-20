@echo off
rem Issue 1291 C11 (B21_11) armour everywhere (R374), frozen pin board/pin-1291-c11d = b0648f5423ce61095a14f06710a0a380d02c8383 (issue 1389).
set "SHIP=chorus_C11" & set "CODE=B21_11" & set "BRANCH=board/pin-1291-c11d" & set "JOB_DIR=opus1291c11d" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
