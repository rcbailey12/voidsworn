@echo off
rem Issue 1412: build the merged Navy Picket H7 v2 (Astra hull with the Opus fittings, R442) from branch opus/pin-1412-h7m (PR 1725). Replaces the stale OPUS1412_H7_SHIPJOB.bat.
set "SHIP=hegemony_H7" & set "CODE=H7_23" & set "BRANCH=opus/pin-1412-h7m" & set "JOB_DIR=opus1412h7m"
set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
