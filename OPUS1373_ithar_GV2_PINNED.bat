@echo off
rem Issue 1373: strike craft ithar_GV2 (R370, Nov 16 pick), ship job trial, SETS=close, no publish
rem Board: frozen pin branch board/pin-1373g (ship_job builds the branch tip, issue 1389); checks the commit= line after.
set "PIN=3f0732b24cd61861489cc535ed36066f3214a0c4"
set "SHIP=ithar_GV2" & set "CODE=ithar_GV2" & set "BRANCH=board/pin-1373g" & set "JOB_DIR=opus1373gv2" & set "SETS=close"
set "RX=%USERPROFILE%\Downloads\voidsworn_test\opus1373gv2\out\result.txt"
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
