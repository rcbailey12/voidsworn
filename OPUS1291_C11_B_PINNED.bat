@echo off
rem Issue 1291: C11 run B, round G on kit 6f79e00c, trial only
rem Board: pinned wrapper; after the shared ship job ends it checks the commit= line.
set "PIN=23edc0aa02313dbb49475a6c87bf585c97101661"
set "SHIP=chorus_C11" & set "CODE=B21_11" & set "BRANCH=work/issue-1291-c11" & set "JOB_DIR=opus1291c11b" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
set "RX=%USERPROFILE%\Downloads\voidsworn_test\opus1291c11b\out\result.txt"
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
