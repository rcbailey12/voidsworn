@echo off
rem Issue 1373: strike craft ithar_GF1, ship job trial, SETS=close, no publish
rem Board: pinned wrapper; after the shared ship job ends it checks the commit= line.
set "PIN=3d7f5499430cb08fec49524c278592b23d8fb033"
set "SHIP=ithar_GF1" & set "CODE=ithar_GF1" & set "BRANCH=opus/issue-1373" & set "JOB_DIR=opus1373b" & set "SETS=close"
set "RX=%USERPROFILE%\Downloads\voidsworn_test\opus1373b\out\result.txt"
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
