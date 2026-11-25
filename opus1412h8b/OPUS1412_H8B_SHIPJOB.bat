@echo off
rem Issue 1412: rerun of the Navy Cordon H8 (merged sheet, main b6b3bb30) after the Nov 25 stage 2 failure. Branch opus/pin-1412-h8b = b6b3bb30 plus the Trellis logging fix. Replaces OPUS1412_H8_SHIPJOB.bat. Run GPU solo, after H7P.
set "SHIP=hegemony_H8" & set "CODE=H8_23" & set "BRANCH=opus/pin-1412-h8b" & set "JOB_DIR=opus1412h8b"
set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
