@echo off
rem Board: frozen pin board/pin-1414d = 813f88f5eee053b29a71515efdae7b1932d5ccf1 (ship_job builds the branch tip, issue 1389).
rem First PC run of a build-sheet ship: all seven stages. Stages 1 to 3 write concept.png, the TRELLIS shape reference (b0.npz)
rem and concept_camera.json that stage 4 scores against; the earlier bat ran 4 to 7 only and stage 4 found no camera.
set "SHIP=voidsworn_S11" & set "CODE=V15_37" & set "BRANCH=board/pin-1414d" & set "JOB_DIR=opus1414d"
set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
