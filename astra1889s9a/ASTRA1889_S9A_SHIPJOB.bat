@echo off
rem Issue 1889 blind pair 2, Astra leg: the full recipe for the Astra Warden rebuild (voidsworn_S9A) from codex/issue-1889; installs into its own job clone only.
set "SHIP=voidsworn_S9A" & set "CODE=V14_23" & set "BRANCH=codex/issue-1889" & set "JOB_DIR=astra1889s9a"
set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
