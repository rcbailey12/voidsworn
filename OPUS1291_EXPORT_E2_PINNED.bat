@echo off
rem Issue 1291 run E2 (trial only): chorus_C13 / B20_11 through the shared ship job, satin veils (kit commit 7710e842).
rem Board: pinned wrapper around the helper's three-line E2; after the shared job ends it checks the commit= line.
set "PIN=ece215c5b45dde198c936c3b21234da7ec3964aa"
set "SHIP=chorus_C13" & set "CODE=B20_11" & set "BRANCH=opus/issue-1291" & set "JOB_DIR=opus1291e" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
set "R1291=%USERPROFILE%\Downloads\voidsworn_test\opus1291e\out\result.txt"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
set "EL1291=%errorlevel%"
findstr /b /c:"commit=%PIN%" "%R1291%" > nul
if errorlevel 1 (
  echo PIN MISMATCH: expected commit=%PIN% >> "%R1291%"
  echo all done >> "%R1291%"
  exit /b 1
)
echo pin ok %PIN% >> "%R1291%"
exit /b %EL1291%
