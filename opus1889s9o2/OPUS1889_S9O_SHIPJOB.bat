@echo off
rem Issue 1889 blind pair 2, Opus leg: the full recipe for the Opus Warden rebuild (voidsworn_S9O) from its pin branch; installs into its own job clone only.
set "SHIP=voidsworn_S9O" & set "CODE=V14_23" & set "BRANCH=opus/pin-1889-s9o" & set "JOB_DIR=opus1889s9o"
set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
