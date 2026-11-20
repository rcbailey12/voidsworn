@echo off
rem Issue 1373: strike craft corsair_KF1, ship job trial, SETS=close, no publish
rem Board: pinned wrapper; after the shared ship job ends it checks the commit= line.
set "PIN=8ba7c27b0091726754f5cb5cda29c5c04797fc73"
set "SHIP=corsair_KF1" & set "CODE=corsair_KF1" & set "BRANCH=opus/issue-1373" & set "JOB_DIR=opus1373e" & set "SETS=close"
set "RX=%USERPROFILE%\Downloads\voidsworn_test\opus1373e\out\result.txt"
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
