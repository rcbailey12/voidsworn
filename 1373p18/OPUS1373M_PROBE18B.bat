@echo off
rem OPUS1373M_PROBE18B.bat (Board: PROBE18 with the watchdog from tools_live\<current.txt>, fail closed; issue 1373 thread, Nov 21; copy of OPUS1373L_PROBE17.bat): the squadron probe at board/pin-1373m (44987b5b)
rem with GV2 (opus1373gv2m) and GW4 (opus1373gw4m), the marble Glasswright craft, as installed craft.
rem Needs probe1373m_prep.ps1 in the same folder. Output opus1373probe18\out, end line "1373M PROBE18 exit". Appends to %L% if set, else opus1373probe18_log.txt. Never deletes.
setlocal EnableDelayedExpansion
set "V=%USERPROFILE%\Downloads\voidsworn_test"
if not defined L set "L=%V%\opus1373probe18_log.txt"
set "W=%V%\opus1373probe18"
set "SQUADRON_ENTRIES=%V%\opus1373gv2m\out\recipe\export\ithar_GV2\manifest_entry.json,%V%\opus1373gw4m\out\recipe\export\ithar_GW4\manifest_entry.json"
set "SQUADRON_EXPECT=ithar|fighter=ithar_GV2,ithar|bomber=ithar_GW4"
set "R=%V%\opus1373probe11\repo"
set /p G=<"%V%\godot_path.txt"
set "TLV="
if exist "%V%\tools_live\current.txt" set /p TLV=<"%V%\tools_live\current.txt"
if not defined TLV (echo 1373M PROBE18 exit 2 at %TIME%, no tools_live\current.txt >> "%L%" & goto done)
set "TM=%V%\tools_live\!TLV!\pc\tmo.bat"
if not exist "!TM!" (echo 1373M PROBE18 exit 2 at %TIME%, no watchdog !TM! >> "%L%" & goto done)
if exist "%W%" (echo 1373M PROBE18 exit 1 at %TIME%, %W% exists >> "%L%" & goto done)
mkdir "%W%"
echo PROBE18 prep %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0probe1373m_prep.ps1" >> "%L%" 2>&1
if errorlevel 1 (echo 1373M PROBE18 exit 1 at %TIME%, prep failed >> "%L%" & goto done)
set "PC_GPU_ISSUE=1373"
call "!TM!" 1800 "%G%" --headless --path "%R%\godot" --import > "%W%\log_import.txt" 2>&1
echo import exit !ERRORLEVEL! at %TIME% >> "%L%"
set "SQUADRON_OUT=%W%\out"
set "PC_GPU_MODE=solo"
echo PROBE18 start %TIME% >> "%L%"
call "!TM!" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --resolution 2560x1440 --script res://fx/test/squadron_probe.gd > "%W%\log_probe.txt" 2>&1
echo 1373M PROBE18 exit !ERRORLEVEL! at %TIME% >> "%L%"
set "PC_GPU_MODE="
set "SQUADRON_OUT="
:done
exit /b 0
