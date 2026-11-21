@echo off
rem Issue 1413 detail round 4 (shared Navy stack: full plate seams; pin includes the 1521 detail gate). All seven stages.
set "SHIP=hegemony_O2" & set "CODE=O2_37" & set "BRANCH=board/pin-1413f" & set "JOB_DIR=opus1413o2f"
set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
