@echo off
rem Issue 1412: build the Navy Cordon H8 from its merged sheet (main b6b3bb30, PR 1716): all seven recipe stages, then the in-game shots at camera 170 and close.
set "SHIP=hegemony_H8" & set "CODE=H8_23" & set "BRANCH=opus/pin-1412-b6b3bb30" & set "JOB_DIR=opus1412h8"
set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
