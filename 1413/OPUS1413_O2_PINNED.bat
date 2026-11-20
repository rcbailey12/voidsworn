@echo off
rem Board: frozen pin board/pin-1413 = 85819dc18756842942de5c8a97fe8a82e4412b28 (ship_job builds the branch tip, issue 1389).
set "SHIP=hegemony_O2" & set "CODE=O2_37" & set "BRANCH=board/pin-1413" & set "JOB_DIR=opus1413o2"
set "STAGES=4_parts_kit 5_paint_bake 6_lod 7_export"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
