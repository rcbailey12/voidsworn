@echo off
rem Sunward spire ember "a bit brighter" (Ryan, Nov 20 13:43 UTC): S8 then S9 rerun after the seam fix (PR 1344), rebuilt on opus/issue-1158-ember, pinned.
rem Each run is the shared ship_job.bat in its own job folder; after each, the run's commit= line is checked against the pin.
set "PIN=b1687ca1a6d3210e700544c5b347473e807a8417"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "SUM=%VT%\opus1158f_summary.txt"
echo start %DATE% %TIME% pin %PIN% > "%SUM%"

set "SHIP=voidsworn_S8" & set "CODE=V1b_r_23" & set "BRANCH=opus/issue-1158-ember" & set "JOB_DIR=opus1158e8"
call "%VT%\ship_job\ship_job.bat"
set "R=%VT%\opus1158e8\out\result.txt"
findstr /b /c:"commit=%PIN%" "%R%" > nul
if errorlevel 1 (echo PIN MISMATCH: expected commit=%PIN% >> "%R%" & echo S8 PIN MISMATCH >> "%SUM%") else (echo pin ok %PIN% >> "%R%" & echo S8 pin ok >> "%SUM%")
findstr /c:"done PASS" "%R%" > nul && echo S8 done PASS >> "%SUM%" || echo S8 FAILED, see opus1158e8\out\result.txt >> "%SUM%"

set "SHIP=voidsworn_S9" & set "CODE=V14_23" & set "BRANCH=opus/issue-1158-ember" & set "JOB_DIR=opus1158e9"
call "%VT%\ship_job\ship_job.bat"
set "R=%VT%\opus1158e9\out\result.txt"
findstr /b /c:"commit=%PIN%" "%R%" > nul
if errorlevel 1 (echo PIN MISMATCH: expected commit=%PIN% >> "%R%" & echo S9 PIN MISMATCH >> "%SUM%") else (echo pin ok %PIN% >> "%R%" & echo S9 pin ok >> "%SUM%")
findstr /c:"done PASS" "%R%" > nul && echo S9 done PASS >> "%SUM%" || echo S9 FAILED, see opus1158e9\out\result.txt >> "%SUM%"

echo all done %DATE% %TIME% >> "%SUM%"
findstr /c:"FAILED" /c:"MISMATCH" "%SUM%" > nul && exit /b 1
exit /b 0
