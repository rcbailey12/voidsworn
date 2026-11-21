@echo off
title Ship line BW: 1373 GW4H rebuild on board/pin-1373h, then PROBE15 (Board, Nov 21) - GPU jobs
rem Board, Nov 21 01:26 UTC (Ryan's in-game notes on the Chorus trail and the GW4 bomber colours; inbox e3fcabe3 holds 7b7e17b9's file): waits (60 s steps) for "1415B GA1 exit" in chain_1119bs3.txt, refreshes repo-mirror.git
rem (pin-1373h f39d1b14), runs OPUS1373H_ithar_GW4.bat (c24773c0, opus1373gw4h, SETS=close, all stages) unedited, trial only; end line "1373 GW4H exit". Then, only if GW4H passed, PROBE15: the probe14 step from
rem HELPERS_CHAIN_1119BR3.bat with clone at f39d1b14 (board1119\probe1373h_prep.ps1), ithar_GW4 kit and manifest entry from opus1373gw4h, GV2 and the other three as probe14, same SQUADRON_EXPECT,
rem output opus1373probe15\out; end line "1373 PROBE15 exit". Writes chain_1119bw.txt. Never deletes.
setlocal EnableDelayedExpansion
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\chain_1119bw.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
echo chain BW waiting for 1415B GA1 exit in chain_1119bs3.txt %DATE% %TIME% > "%L%"
:wait
findstr /b /c:"1415B GA1 exit" "%V%\chain_1119bs3.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\mirror_refresh_any.ps1" f39d1b1479956c445117ead3f8b0501cdbc8e067 >> "%L%" 2>&1
echo 1373 GW4H start %TIME% >> "%L%"
setlocal & set "PIN=" & set "PUBLISH=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "SHIP=" & set "CODE=" & set "BRANCH=" & set "JOB_DIR=" & set "FACS=" & set "PC_GPU_ISSUE=1373" & call "%V%\OPUS1373H_ithar_GW4.bat" & endlocal
echo 1373 GW4H exit %ERRORLEVEL% at %TIME% >> "%L%"
findstr /b /c:"done PASS" "%V%\opus1373gw4h\out\result.txt" >nul 2>&1 || (echo 1373 PROBE15 exit 1 at %TIME%, not run: GW4H did not pass >> "%L%" & goto done)
set "SQUADRON_ENTRIES=%V%\opus1373n\out\recipe\export\chorus_CS1BA2\manifest_entry.json,%V%\opus1373gv2\out\recipe\export\ithar_GV2\manifest_entry.json,%V%\opus1373gw4h\out\recipe\export\ithar_GW4\manifest_entry.json,%V%\opus1373q\out\recipe\export\hegemony_HB1\manifest_entry.json,%V%\opus1373r\out\recipe\export\corsair_KF1\manifest_entry.json"
set "SQUADRON_EXPECT=voidsworn|fighter=voidsworn_SF3,voidsworn|bomber=voidsworn_SB4,hegemony|fighter=hegemony_HF1D,hegemony|bomber=hegemony_HB1,corsair|bomber=corsair_KB1CC,corsair|fighter=corsair_KF1,chorus|spore=chorus_CS1BA2,ithar|fighter=ithar_GV2,ithar|bomber=ithar_GW4"
set "W=%V%\opus1373probe15"
set "R=%V%\opus1373probe11\repo"
set /p G=<"%V%\godot_path.txt"
echo PROBE15 prep %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\probe1373h_prep.ps1" >> "%L%" 2>&1
if errorlevel 1 (echo 1373 PROBE15 exit 1 at %TIME%, prep failed >> "%L%" & goto done)
if exist "%W%" (echo 1373 PROBE15 exit 1 at %TIME%, %W% exists >> "%L%" & goto done)
mkdir "%W%"
set "PC_GPU_ISSUE=1373"
call "%V%\build\tools\pc\tmo.bat" 1800 "%G%" --headless --path "%R%\godot" --import > "%W%\log_import.txt" 2>&1
echo import exit !ERRORLEVEL! at %TIME% >> "%L%"
set "SQUADRON_OUT=%W%\out"
set "PC_GPU_MODE=solo"
echo PROBE15 start %TIME% >> "%L%"
call "%V%\build\tools\pc\tmo.bat" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --resolution 2560x1440 --script res://fx/test/squadron_probe.gd > "%W%\log_probe.txt" 2>&1
echo 1373 PROBE15 exit !ERRORLEVEL! at %TIME% >> "%L%"
set "PC_GPU_MODE="
set "SQUADRON_OUT="
:done
set "JTLV=9204dbb0c395"
if exist "%V%\tools_live\current.txt" set /p JTLV=<"%V%\tools_live\current.txt"
if exist "%V%\tools_live\%JTLV%\pc\janitor.bat" call "%V%\tools_live\%JTLV%\pc\janitor.bat" --after-job >> "%V%\janitor_after_1119bw.txt" 2>&1
echo after-job janitor ran %TIME% >> "%L%"
echo all done %DATE% %TIME% >> "%L%"
exit /b 0