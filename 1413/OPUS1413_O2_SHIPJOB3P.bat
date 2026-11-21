@echo off
rem First PC run of a build-sheet ship: all seven stages. Stages 1 to 3 write concept.png, the TRELLIS shape reference (b0.npz)
rem and concept_camera.json that stage 4 scores against; the earlier bat ran 4 to 7 only and stage 4 found no camera.
set "SHIP=hegemony_O2" & set "CODE=O2_37" & set "BRANCH=board/pin-1413c" & set "JOB_DIR=opus1413o2c"
set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
