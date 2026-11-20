@echo off
rem Issue 1282 W3: CD5 with four hp_rcs points (PC coverage before merge), all seven stages and shots.
rem close and cams shots. New since W1C: the optics train again (seat lowered), the readback now fails a locked turret, and
rem the game maps have a rougher pearl (the white bloom at the stern). No legacy hull step (no built old Glasswright hull).
rem Board: pinned; after the shared job ends this wrapper checks the run's commit= line against the pin.
set "PIN=6548e4eadd62dc65a838119d3ca6fd167b6f0ca2"
set "SHIP=ithar_CD5" & set "CODE=I8_37" & set "BRANCH=opus/issue-1282" & set "JOB_DIR=opus1282w3" & set "SETS=battle,close,cams"
set "R1282=%USERPROFILE%\Downloads\voidsworn_test\opus1282w3\out\result.txt"
call "%USERPROFILE%\Downloads\voidsworn_test\ship_job\ship_job.bat"
set "EL1282=%errorlevel%"
findstr /b /c:"commit=%PIN%" "%R1282%" > nul
if errorlevel 1 (
  echo PIN MISMATCH: expected commit=%PIN% >> "%R1282%"
  echo all done >> "%R1282%"
  exit /b 1
)
echo pin ok %PIN% >> "%R1282%"
exit /b %EL1282%
