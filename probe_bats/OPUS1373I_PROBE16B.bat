@echo off
rem OPUS1373I_PROBE16B.bat (Board, Nov 21 02:55 UTC; PROBE16 with its fused line 7 split): the 1373 squadron probe at board/pin-1373i (84b6e3f4). Copy of the PROBE15 step in HELPERS_CHAIN_1119BW.bat (itself the probe14 step of
rem HELPERS_CHAIN_1119BR3.bat) with only: clone at 84b6e3f4 (board1119\probe1373i_prep.ps1), GV2 kit and entry from opus1373gv2i, GW4 kit and entry from opus1373gw4i, output opus1373probe16\out,
rem end line "1373I PROBE16 exit". Other three craft, SQUADRON_EXPECT, import and probe calls unchanged. Appends to %L% (chain log) if set, else opus1373probe16_log.txt. Never deletes.
setlocal EnableDelayedExpansion
set "V=%USERPROFILE%\Downloads\voidsworn_test"
if not defined L set "L=%V%\opus1373probe16_log.txt"
set "SQUADRON_ENTRIES=%V%\opus1373n\out\recipe\export\chorus_CS1BA2\manifest_entry.json,%V%\opus1373gv2i\out\recipe\export\ithar_GV2\manifest_entry.json,%V%\opus1373gw4i\out\recipe\export\ithar_GW4\manifest_entry.json,%V%\opus1373q\out\recipe\export\hegemony_HB1\manifest_entry.json,%V%\opus1373r\out\recipe\export\corsair_KF1\manifest_entry.json"
set "SQUADRON_EXPECT=voidsworn|fighter=voidsworn_SF3,voidsworn|bomber=voidsworn_SB4,hegemony|fighter=hegemony_HF1D,hegemony|bomber=hegemony_HB1,corsair|bomber=corsair_KB1CC,corsair|fighter=corsair_KF1,chorus|spore=chorus_CS1BA2,ithar|fighter=ithar_GV2,ithar|bomber=ithar_GW4"
set "W=%V%\opus1373probe16"
set "R=%V%\opus1373probe11\repo"
set /p G=<"%V%\godot_path.txt"
echo PROBE16 prep %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\probe1373i_prep.ps1" >> "%L%" 2>&1
if errorlevel 1 (echo 1373I PROBE16 exit 1 at %TIME%, prep failed >> "%L%" & goto done)
if exist "%W%" (echo 1373I PROBE16 exit 1 at %TIME%, %W% exists >> "%L%" & goto done)
mkdir "%W%"
set "PC_GPU_ISSUE=1373"
call "%V%\build\tools\pc\tmo.bat" 1800 "%G%" --headless --path "%R%\godot" --import > "%W%\log_import.txt" 2>&1
echo import exit !ERRORLEVEL! at %TIME% >> "%L%"
set "SQUADRON_OUT=%W%\out"
set "PC_GPU_MODE=solo"
echo PROBE16 start %TIME% >> "%L%"
call "%V%\build\tools\pc\tmo.bat" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --resolution 2560x1440 --script res://fx/test/squadron_probe.gd > "%W%\log_probe.txt" 2>&1
echo 1373I PROBE16 exit !ERRORLEVEL! at %TIME% >> "%L%"
set "PC_GPU_MODE="
set "SQUADRON_OUT="
:done
exit /b 0
