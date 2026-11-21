@echo off
rem Issue 1413: H10 with the round 3 Navy kit, for the before/after Ryan sees beside O2 and O3. Output only, no install.
set "SHIP=hegemony_H10" & set "CODE=H10_23" & set "BRANCH=board/pin-1413e" & set "JOB_DIR=opus1413h10e"
set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
