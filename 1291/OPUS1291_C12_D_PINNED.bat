@echo off
rem Issue 1291 C12 (B19_11) armour everywhere (R374), frozen pin board/pin-1291-wrap1 = 392b9468b495d66cad4ffac29a6fe95d6f27a1fc (issue 1389).
set "SHIP=chorus_C12" & set "CODE=B19_11" & set "BRANCH=board/pin-1291-wrap1" & set "JOB_DIR=opus1291c12d" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
