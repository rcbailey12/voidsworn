@echo off
title Ship line BR3: Harrow 1414C, 1373 GV2 and GW4, then the 1373 probe (Board, Nov 20) - GPU jobs
rem Board, Nov 20 22:38 UTC (BR3 replaces BR2, stopped before it ran; Board 23:17 UTC: never copy ships while the C10 E publish runs): waits (60 s steps) for "1155 C14_H exit" in chain_1119bq.txt AND "PUBLISH C10E exit" in opus1399_burst2b_wait.txt, refreshes repo-mirror.git (pin-1414c f4867b99, pin-1373g 3f0732b2), then runs
rem OPUS1414C_SHIPJOB_PINNED (b09b2f42, opus1414c), OPUS1373_ithar_GV2_PINNED (a5d9acd9, opus1373gv2), OPUS1373_ithar_GW4_PINNED (9d16aa4d, opus1373gw4), unedited, trial only,
rem continuing past a failure; then the squadron probe in opus1373probe11\repo checked out to 3f0732b2 (board1119\probe1373g_prep.ps1), GPU solo, SQUADRON_EXPECT with GV2 and GW4,
rem SQUADRON_ENTRIES the five current craft, output opus1373probe14\out. End lines "1414C S11 exit", "1373 ithar_GV2 exit", "1373 ithar_GW4 exit", "OPUS1373 probe exit". Writes chain_1119br.txt.
setlocal EnableDelayedExpansion
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\chain_1119br.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
echo chain BR3 waiting for 1155 C14_H exit in chain_1119bq.txt and PUBLISH C10E exit in opus1399_burst2b_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"1155 C14_H exit" "%V%\chain_1119bq.txt" >nul 2>&1 || goto sleep
findstr /b /c:"PUBLISH C10E exit" "%V%\opus1399_burst2b_wait.txt" >nul 2>&1 && goto go
:sleep
timeout /t 60 /nobreak >nul
goto wait
:go
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\mirror_refresh_any.ps1" f4867b996a7591f4f5897c427ca0d650b5c02316 3f0732b24cd61861489cc535ed36066f3214a0c4 >> "%L%" 2>&1
echo 1414C S11 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "PUBLISH=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "SHIP=" & set "CODE=" & set "BRANCH=" & set "JOB_DIR=" & set "FACS=" & set "PC_GPU_ISSUE=1414" & call "%V%\OPUS1414C_SHIPJOB_PINNED.bat" & endlocal
echo 1414C S11 exit %ERRORLEVEL% at %TIME% >> "%L%"
echo 1373 ithar_GV2 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "PUBLISH=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "SHIP=" & set "CODE=" & set "BRANCH=" & set "JOB_DIR=" & set "FACS=" & set "PC_GPU_ISSUE=1373" & call "%V%\OPUS1373_ithar_GV2_PINNED.bat" & endlocal
echo 1373 ithar_GV2 exit %ERRORLEVEL% at %TIME% >> "%L%"
echo 1373 ithar_GW4 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "PUBLISH=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "SHIP=" & set "CODE=" & set "BRANCH=" & set "JOB_DIR=" & set "FACS=" & set "PC_GPU_ISSUE=1373" & call "%V%\OPUS1373_ithar_GW4_PINNED.bat" & endlocal
echo 1373 ithar_GW4 exit %ERRORLEVEL% at %TIME% >> "%L%"
set "SQUADRON_ENTRIES=%V%\opus1373n\out\recipe\export\chorus_CS1BA2\manifest_entry.json,%V%\opus1373gv2\out\recipe\export\ithar_GV2\manifest_entry.json,%V%\opus1373gw4\out\recipe\export\ithar_GW4\manifest_entry.json,%V%\opus1373q\out\recipe\export\hegemony_HB1\manifest_entry.json,%V%\opus1373r\out\recipe\export\corsair_KF1\manifest_entry.json"
set "SQUADRON_EXPECT=voidsworn|fighter=voidsworn_SF3,voidsworn|bomber=voidsworn_SB4,hegemony|fighter=hegemony_HF1D,hegemony|bomber=hegemony_HB1,corsair|bomber=corsair_KB1CC,corsair|fighter=corsair_KF1,chorus|spore=chorus_CS1BA2,ithar|fighter=ithar_GV2,ithar|bomber=ithar_GW4"
set "W=%V%\opus1373probe14"
set "R=%V%\opus1373probe11\repo"
set /p G=<"%V%\godot_path.txt"
echo probe prep %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\probe1373g_prep.ps1" >> "%L%" 2>&1
if errorlevel 1 (echo OPUS1373 probe exit 1 at %TIME%, prep failed >> "%L%" & goto done)
if exist "%W%" (echo OPUS1373 probe exit 1 at %TIME%, %W% exists >> "%L%" & goto done)
mkdir "%W%"
set "PC_GPU_ISSUE=1373"
call "%V%\build\tools\pc\tmo.bat" 1800 "%G%" --headless --path "%R%\godot" --import > "%W%\log_import.txt" 2>&1
echo import exit !ERRORLEVEL! at %TIME% >> "%L%"
set "SQUADRON_OUT=%W%\out"
set "PC_GPU_MODE=solo"
echo probe start %TIME% >> "%L%"
call "%V%\build\tools\pc\tmo.bat" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --resolution 2560x1440 --script res://fx/test/squadron_probe.gd > "%W%\log_probe.txt" 2>&1
echo OPUS1373 probe exit !ERRORLEVEL! at %TIME% >> "%L%"
set "PC_GPU_MODE="
set "SQUADRON_OUT="
:done
set "JTLV=9204dbb0c395"
if exist "%V%\tools_live\current.txt" set /p JTLV=<"%V%\tools_live\current.txt"
if exist "%V%\tools_live\%JTLV%\pc\janitor.bat" call "%V%\tools_live\%JTLV%\pc\janitor.bat" --after-job >> "%V%\janitor_after_1119br.txt" 2>&1
echo after-job janitor ran %TIME% >> "%L%"
echo all done %DATE% %TIME% >> "%L%"
exit /b 0
