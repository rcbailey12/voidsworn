@echo off
rem Issue 1291 run G (trial only): chorus_C13 / B20_11, round F plus flat sac caps (kit f23c6274).
rem Board: pinned wrapper around the helper's helper G (sha d4bf45b8); after the shared job ends it checks the commit= line.
set "PIN=f77b42467d6bf69b4558206f7ce0b53226a150ec"
set "SHIP=chorus_C13" & set "CODE=B20_11" & set "BRANCH=opus/issue-1291" & set "JOB_DIR=opus1291g" & set "FACS=chorus" & set "STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
set "R1291=%USERPROFILE%\Downloads\voidsworn_test\opus1291g\out\result.txt"
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
