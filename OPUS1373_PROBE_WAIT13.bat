@echo off
title GPU line: 1373 squadron_probe rerun at 93381cfe with verified SQUADRON_ENTRIES, GPU solo (Board, Nov 20)
rem Board, Nov 20 21:27 UTC (replaces WAIT12, stopped before it ran): waits (60 s steps) for "OPUS1399_LOOK2 exit" in opus1399_look2_wait.txt, then reruns res://fx/test/squadron_probe.gd in the
rem existing opus1373probe11\repo (checked out to 93381cfe, board/pin-1373f, on the PC by a plain checkout: only squadron_probe.gd changed; its import cache and the five kits kept),
rem through build\tools\pc\tmo.bat with PC_GPU_MODE=solo, PC_GPU_ISSUE=1373, SQUADRON_EXPECT as before, SQUADRON_ENTRIES = the five jobs' manifest_entry.json,
rem SQUADRON_OUT=opus1373probe13\out. End line "OPUS1373 probe exit". Writes opus1373probe13_wait.txt. Never deletes.
setlocal EnableDelayedExpansion
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "R=%V%\opus1373probe11\repo"
set "W=%V%\opus1373probe13"
set "L=%V%\opus1373probe13_wait.txt"
set "PC_GPU_ISSUE=1373"
set "PC_GPU_WAIT_SECONDS=3600"
set /p G=<"%V%\godot_path.txt"
echo waiting for OPUS1399_LOOK2 exit in opus1399_look2_wait.txt %DATE% %TIME% > "%L%"
:wait
findstr /b /c:"OPUS1399_LOOK2 exit" "%V%\opus1399_look2_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if exist "%W%" (echo FAIL: %W% already exists >> "%L%" & echo OPUS1373 probe exit 1 at %TIME% >> "%L%" & exit /b 1)
mkdir "%W%"
for /f %%H in ('git -C "%R%" rev-parse HEAD') do echo clone at %%H >> "%L%"
set "SQUADRON_OUT=%W%\out"
set "PC_GPU_MODE=solo"
set "SQUADRON_EXPECT=voidsworn|fighter=voidsworn_SF3,voidsworn|bomber=voidsworn_SB4,hegemony|fighter=hegemony_HF1D,hegemony|bomber=hegemony_HB1,corsair|bomber=corsair_KB1CC,corsair|fighter=corsair_KF1,chorus|spore=chorus_CS1BA2,ithar|fighter=ithar_GF1,ithar|bomber=ithar_GB1"
set "SQUADRON_ENTRIES=%V%\opus1373n\out\recipe\export\chorus_CS1BA2\manifest_entry.json,%V%\opus1373o\out\recipe\export\ithar_GF1\manifest_entry.json,%V%\opus1373p\out\recipe\export\ithar_GB1\manifest_entry.json,%V%\opus1373q\out\recipe\export\hegemony_HB1\manifest_entry.json,%V%\opus1373r\out\recipe\export\corsair_KF1\manifest_entry.json"
echo probe start %TIME% >> "%L%"
call "%V%\build\tools\pc\tmo.bat" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --resolution 2560x1440 --script res://fx/test/squadron_probe.gd > "%W%\log_probe.txt" 2>&1
echo OPUS1373 probe exit !ERRORLEVEL! at %TIME% >> "%L%"
exit /b 0