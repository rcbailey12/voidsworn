@echo off
rem Issue 1291: C12 run B, round G on kit 6f79e00c, trial only
rem Board: pinned wrapper; after the shared ship job ends it checks the commit= line.
set "PIN=bade6c5fb3491e60093739ceb5f3feffaa94c5e2"
set "SHIP=chorus_C12" & set "CODE=B19_11" & set "BRANCH=work/issue-1291-c12" & set "JOB_DIR=opus1291c12b" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
set "RX=%USERPROFILE%\Downloads\voidsworn_test\opus1291c12b\out\result.txt"
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
