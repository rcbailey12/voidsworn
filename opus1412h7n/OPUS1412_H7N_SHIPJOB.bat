@echo off
rem Issue 1412: build the Navy Picket H7 v3 (Astra hull, fewer Opus fittings on its structure, after Ryan's review) from branch opus/pin-1412-h7n (PR 1725). Replaces OPUS1412_H7M_SHIPJOB.bat.
set "SHIP=hegemony_H7" & set "CODE=H7_23" & set "BRANCH=opus/pin-1412-h7n" & set "JOB_DIR=opus1412h7n"
set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
