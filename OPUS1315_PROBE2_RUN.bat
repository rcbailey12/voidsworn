@echo off
title Opus 1315 bloom probe 2 (a4 rig) - GPU job
rem Issue 1315, second probe (replaces OPUS1315_PROBE_RUN.bat; Artoo on PR 1317). Runs inside the a4_shots rig itself
rem (same sky, lights, look, ShipView and view q) on the W2 installed CD5 in opus1282w2's clone, once per variant (glow off,
rem emission off, metal 0.3 and 0, rough 0.45, key off, fill off, sky reflections off), and counts the stern box the
rem same way as the bar (W2's own I8_37_q.jpg: 1290 pixels over 245). The probe is read from pinned commit 2d48db67 and
rem copied into an untracked folder of that clone (godot\zz_opus1315_probe); nothing tracked changes. Writes only there and
rem under opus1315\out_<A>. Deletes nothing. Ends with "all done".
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "C=%V%\opus1282w2\repo"
set "W=%V%\opus1315"
set "PIN=2d48db679765c5d6f166267e899ba001f83cd5d4"
if not exist "%W%" mkdir "%W%"
set A=1
:findattempt
if exist "%W%\out_%A%" (set /a A+=1 & goto findattempt)
set "O=%W%\out_%A%"
mkdir "%O%"
set "RES=%O%\result.txt"
echo start %DATE% %TIME% attempt %A% probe2 pin %PIN% > "%RES%"
findstr /b /c:"GPU cleared" "%V%\gpu_go.txt" >nul 2>&1 || (echo gpu_go.txt is not GPU cleared: stopped >> "%RES%" & goto done)
set "GLB=%C%\godot\assets\ships\I8_37\I8_37.glb"
if not exist "%GLB%" (echo FAILED: no W2 install at %GLB% >> "%RES%" & goto done)
certutil -hashfile "%GLB%" SHA256 >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin %PIN% >> "%RES%" 2>&1
if errorlevel 1 (echo FAILED: fetch %PIN% >> "%RES%" & goto done)
set "P=%C%\godot\zz_opus1315_probe"
if not exist "%P%" mkdir "%P%"
git -C "%C%" show %PIN%:godot/bench/opus1315/bloom_probe.gd > "%P%\bloom_probe.gd" 2>> "%RES%"
if errorlevel 1 (echo FAILED: could not read the probe script >> "%RES%" & goto done)
echo [gd_scene load_steps=2 format=3]> "%P%\bloom_probe.tscn"
echo.>> "%P%\bloom_probe.tscn"
echo [ext_resource type="Script" path="res://zz_opus1315_probe/bloom_probe.gd" id="1"]>> "%P%\bloom_probe.tscn"
echo.>> "%P%\bloom_probe.tscn"
echo [node name="BloomProbe" type="Node3D"]>> "%P%\bloom_probe.tscn"
echo script = ExtResource("1")>> "%P%\bloom_probe.tscn"
set "TLV="
if exist "%V%\tools_live\current.txt" set /p TLV=<"%V%\tools_live\current.txt"
if not defined TLV (echo FAILED: tools_live\current.txt is missing or empty >> "%RES%" & goto done)
set "TM=%V%\tools_live\%TLV%\pc\tmo.bat"
if not exist "%TM%" (echo FAILED: no watchdog at %TM% >> "%RES%" & goto done)
echo watchdog %TM% >> "%RES%"
set PC_GPU_WAIT_SECONDS=3600
set "PC_GPU_ISSUE=opus1315"
call "%TM%" 1800 "%V%\godot\Godot_v4.7.2-stable_win64_console.exe" --path "%C%\godot" --resolution 1920x1080 res://zz_opus1315_probe/bloom_probe.tscn -- --out "%O%\probe" > "%O%\log_probe.txt" 2>&1
set E=%ERRORLEVEL%
echo probe exit %E% >> "%RES%"
findstr /c:"BLOOM_PROBE" /c:"placeholder hull" "%O%\log_probe.txt" >> "%RES%"
findstr /c:"BLOOM_PROBE done" "%O%\log_probe.txt" >nul && (echo PASSED >> "%RES%") || (echo FAILED: the probe did not finish >> "%RES%")
:done
echo all done %DATE% %TIME% >> "%RES%"
endlocal
