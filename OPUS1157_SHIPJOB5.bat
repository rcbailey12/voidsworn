@echo off
rem Issue 1157 run 5: Vigil S10, death seam fix (B-3 peel moved under the gun deck). Branch head pinned below.
rem The shared ship job takes a branch, so after it ends this wrapper checks the run's commit= line against the pin.
set "PIN=e511d6d5882b5ac57d3a8ce424df0a124afaa0c1"
set "SHIP=voidsworn_S10" & set "CODE=V16_37" & set "BRANCH=opus/issue-1157" & set "JOB_DIR=opus1157"
set "R1157=%USERPROFILE%\Downloads\voidsworn_test\opus1157\out\result.txt"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
set "EL1157=%errorlevel%"
findstr /b /c:"commit=%PIN%" "%R1157%" > nul
if errorlevel 1 (
  echo PIN MISMATCH: expected commit=%PIN% >> "%R1157%"
  echo all done >> "%R1157%"
  exit /b 1
)
echo pin ok %PIN% >> "%R1157%"
exit /b %EL1157%
