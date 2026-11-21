@echo off
rem OPUS1373L_PROBE17.bat (issue 1373 thread, Nov 21; copy of the Board's OPUS1373I_PROBE16B.bat): the squadron probe at board/pin-1373l (237fd5b2, KF1 drawn at 0.7)
rem with only KF1 (opus1373kf1l) and GV2 (opus1373gv2i, or build\godot if cleaned) as installed craft, for the KF1 beside another fighter size check.
rem Needs probe1373l_prep.ps1 in the same folder. Output opus1373probe17\out, end line "1373L PROBE17 exit". Appends to %L% if set, else opus1373probe17_log.txt. Never deletes.
setlocal EnableDelayedExpansion
set "V=%USERPROFILE%\Downloads\voidsworn_test"
if not defined L set "L=%V%\opus1373probe17_log.txt"
set "W=%V%\opus1373probe17"
set "SQUADRON_ENTRIES=%V%\opus1373kf1l\out\recipe\export\corsair_KF1\manifest_entry.json,%W%\gv2_entry.json"
set "SQUADRON_EXPECT=corsair|fighter=corsair_KF1,ithar|fighter=ithar_GV2"
set "R=%V%\opus1373probe11\repo"
set /p G=<"%V%\godot_path.txt"
if exist "%W%" (echo 1373L PROBE17 exit 1 at %TIME%, %W% exists >> "%L%" & goto done)
mkdir "%W%"
echo PROBE17 prep %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0probe1373l_prep.ps1" >> "%L%" 2>&1
if errorlevel 1 (echo 1373L PROBE17 exit 1 at %TIME%, prep failed >> "%L%" & goto done)
set "PC_GPU_ISSUE=1373"
call "%V%\build\tools\pc\tmo.bat" 1800 "%G%" --headless --path "%R%\godot" --import > "%W%\log_import.txt" 2>&1
echo import exit !ERRORLEVEL! at %TIME% >> "%L%"
set "SQUADRON_OUT=%W%\out"
set "PC_GPU_MODE=solo"
echo PROBE17 start %TIME% >> "%L%"
call "%V%\build\tools\pc\tmo.bat" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --resolution 2560x1440 --script res://fx/test/squadron_probe.gd > "%W%\log_probe.txt" 2>&1
echo 1373L PROBE17 exit !ERRORLEVEL! at %TIME% >> "%L%"
set "PC_GPU_MODE="
set "SQUADRON_OUT="
:done
exit /b 0
