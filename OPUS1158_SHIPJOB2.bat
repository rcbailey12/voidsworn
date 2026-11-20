@echo off
rem Issue 1158 run 2: S8 on the Warden round 3 kit. opus/issue-1158 sits at main 291dfcac (PR 1164 merge).
rem The shared ship job takes a branch, so after it ends this wrapper checks the run's commit= line against the pin.
set "PIN=291dfcaca818fc783c3a808d85c54744051af6ae"
set "SHIP=voidsworn_S8" & set "CODE=V1b_r_23" & set "BRANCH=opus/issue-1158" & set "JOB_DIR=opus1158"
set "R1158=%USERPROFILE%\Downloads\voidsworn_test\opus1158\out\result.txt"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
set "EL1158=%errorlevel%"
findstr /b /c:"commit=%PIN%" "%R1158%" > nul
if errorlevel 1 (
  echo PIN MISMATCH: expected commit=%PIN% >> "%R1158%"
  echo all done >> "%R1158%"
  exit /b 1
)
echo pin ok %PIN% >> "%R1158%"
exit /b %EL1158%
