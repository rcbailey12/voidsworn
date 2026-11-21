@echo off
rem Board: frozen pin board/pin-1291-holes2 = e2b9c8a1e993bac7af2e8017846b444c27a9b1d4 (ship_job builds the branch tip, issue 1389).
set "SHIP=chorus_C14" & set "CODE=B22_11" & set "BRANCH=board/pin-1291-holes2" & set "JOB_DIR=opus1155c14f" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
