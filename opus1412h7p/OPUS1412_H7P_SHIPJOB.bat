@echo off
rem Issue 1412: rerun of the Navy Picket H7 v3 (PR 1725) after the Nov 25 stage 2 failures. Branch opus/pin-1412-h7p = the H7N head plus the Trellis logging fix (every failure logged with its traceback, two lighter pipeline types tried last). Replaces OPUS1412_H7N_SHIPJOB.bat. Run GPU solo.
set "SHIP=hegemony_H7" & set "CODE=H7_23" & set "BRANCH=opus/pin-1412-h7p" & set "JOB_DIR=opus1412h7p"
set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
