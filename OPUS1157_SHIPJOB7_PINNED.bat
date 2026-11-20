@echo off
rem Issue 1157: Vigil S10 round 4, S8 broadside mounts sized to the ship
rem Board: pinned wrapper; after the shared ship job ends it checks the commit= line.
set "PIN=553659bad845df79b7a1481145ed1d238c0a7d5b"
set "SHIP=voidsworn_S10" & set "CODE=V16_37" & set "BRANCH=opus/issue-1157" & set "JOB_DIR=opus1157"
set "RX=%USERPROFILE%\Downloads\voidsworn_test\opus1157\out\result.txt"
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
