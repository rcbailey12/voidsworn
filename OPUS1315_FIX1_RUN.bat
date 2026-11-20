@echo off
rem Issue 1315 FIX1: Glasswright hulls skip the LookRim back light (shared look rig). ship_job on opus/issue-1315,
rem all seven stages for CD5 (I8_37), then battle, close and cams for every Glasswright ship. Mirrors 1282 W3 (the before).
rem Board: pinned; after the shared job ends this wrapper checks the run's commit= line against the pin.
set "PIN=62e693e61dd1d406189f5698cbdedcc271a70d1b"
set "SHIP=ithar_CD5" & set "CODE=I8_37" & set "BRANCH=opus/issue-1315" & set "JOB_DIR=opus1315fix1" & set "SETS=battle,close,cams"
set "R1315=%USERPROFILE%\Downloads\voidsworn_test\opus1315fix1\out\result.txt"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
set "EL1315=%errorlevel%"
findstr /b /c:"commit=%PIN%" "%R1315%" > nul
if errorlevel 1 (
  echo PIN MISMATCH: expected commit=%PIN% >> "%R1315%"
  echo all done >> "%R1315%"
  exit /b 1
)
echo pin ok %PIN% >> "%R1315%"
exit /b %EL1315%
