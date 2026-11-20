@echo off
rem Issue 1157 run 6: Vigil S10, open port bores (broadside variant 1). Branch head pinned below.
rem The shared ship job takes a branch, so after it ends this wrapper checks the run's commit= line against the pin.
set "PIN=ffe2591c6785a8911ecca568bbad6e5da8d16f10"
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
