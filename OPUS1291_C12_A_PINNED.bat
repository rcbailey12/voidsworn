@echo off
rem Issue 1291: C12 round G port, trial only
rem Board: pinned wrapper; after the shared ship job ends it checks the commit= line.
set "PIN=e912ab090ec7a4d59634c3cebcf5ff62336578d3"
set "SHIP=chorus_C12" & set "CODE=B19_11" & set "BRANCH=work/issue-1291-c12" & set "JOB_DIR=opus1291c12a" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
set "RX=%USERPROFILE%\Downloads\voidsworn_test\opus1291c12a\out\result.txt"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
set "ELX=%errorlevel%"
findstr /b /c:"commit=%PIN%" "%RX%" > nul
if errorlevel 1 (
  echo PIN MISMATCH: expected commit=%PIN% >> "%RX%"
  echo all done >> "%RX%"
  exit /b 1
)
echo pin ok %PIN% >> "%RX%"
exit /b %ELX%
