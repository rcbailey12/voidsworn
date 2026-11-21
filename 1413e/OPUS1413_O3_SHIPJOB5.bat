@echo off
rem Issue 1413 detail round 3 (stronger Navy plating seams, Relay lens block plates). All seven stages.
set "SHIP=hegemony_O3" & set "CODE=O3_11" & set "BRANCH=board/pin-1413e" & set "JOB_DIR=opus1413o3e"
set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
