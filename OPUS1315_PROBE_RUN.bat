@echo off
title Opus 1315 bloom probe - GPU job
rem Issue 1315: what makes CD5's white stern bloom. Renders the W2 installed CD5 (opus1282w2's clone) with the a4_shots light
rem rig at view q, once per variant (glow off, emission off, metal 0.3 and 0, rough 0.45, key off, fill off), and counts the
rem saturated pixels. The probe script comes from branch opus/issue-1315 (git show, no checkout); the W2 clone is not changed
rem except for git's FETCH_HEAD. Writes only under opus1315\out_<A>. Deletes nothing. Ends with "all done".
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "C=%V%\opus1282w2\repo"
set "W=%V%\opus1315"
set A=1
:findattempt
if exist "%W%\out_%A%" (set /a A+=1 & goto findattempt)
set "O=%W%\out_%A%"
mkdir "%O%"
set "RES=%O%\result.txt"
echo start %DATE% %TIME% attempt %A% > "%RES%"
findstr /b /c:"GPU cleared" "%V%\gpu_go.txt" >nul 2>&1 || (echo gpu_go.txt is not GPU cleared: stopped >> "%RES%" & goto done)
set "GLB=%C%\godot\assets\ships\I8_37\I8_37.glb"
if not exist "%GLB%" (echo FAILED: no W2 install at %GLB% >> "%RES%" & goto done)
certutil -hashfile "%GLB%" SHA256 >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin opus/issue-1315 >> "%RES%" 2>&1
if errorlevel 1 (echo FAILED: fetch opus/issue-1315 >> "%RES%" & goto done)
git -C "%C%" rev-parse FETCH_HEAD >> "%RES%" 2>&1
git -C "%C%" show FETCH_HEAD:godot/bench/opus1315/bloom_probe.gd > "%O%\bloom_probe.gd" 2>> "%RES%"
if errorlevel 1 (echo FAILED: could not read the probe script >> "%RES%" & goto done)
set "TLV="
if exist "%V%\tools_live\current.txt" set /p TLV=<"%V%\tools_live\current.txt"
if not defined TLV (echo FAILED: tools_live\current.txt is missing or empty >> "%RES%" & goto done)
set "TM=%V%\tools_live\%TLV%\pc\tmo.bat"
if not exist "%TM%" (echo FAILED: no watchdog at %TM% >> "%RES%" & goto done)
echo watchdog %TM% >> "%RES%"
set PC_GPU_WAIT_SECONDS=3600
set "PC_GPU_ISSUE=opus1315"
call "%TM%" 1800 "%V%\godot\Godot_v4.7.2-stable_win64_console.exe" --path "%C%\godot" --resolution 1920x1080 --script "%O%\bloom_probe.gd" -- "%GLB%" "%O%\probe" > "%O%\log_probe.txt" 2>&1
set E=%ERRORLEVEL%
echo probe exit %E% >> "%RES%"
findstr /c:"BLOOM_PROBE" "%O%\log_probe.txt" >> "%RES%"
findstr /c:"BLOOM_PROBE done" "%O%\log_probe.txt" >nul && (echo PASSED >> "%RES%") || (echo FAILED: the probe did not finish >> "%RES%")
:done
echo all done %DATE% %TIME% >> "%RES%"
endlocal
