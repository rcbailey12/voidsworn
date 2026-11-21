@echo off
title Ship line CC: 1373I squadron probe PROBE16 on board/pin-1373i (Board, Nov 21) - GPU solo
rem Board, Nov 21 02:53 UTC: waits (60 s steps) for "1373I GW4 exit" in chain_1119ca.txt, then runs OPUS1373I_PROBE16.bat (sha256 a6f18580) only if both opus1373gv2i and opus1373gw4i passed,
rem else writes "1373I PROBE16 exit 1 ... not run". End line "1373I PROBE16 exit". Writes chain_1119cc.txt. Never deletes. CB2 (1291 holes3) waits for this end line, so GPU claims do not overlap.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\chain_1119cc.txt"
set "PC_GPU_WAIT_SECONDS=3600"
echo chain CC waiting for 1373I GW4 exit in chain_1119ca.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"1373I GW4 exit" "%V%\chain_1119ca.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
findstr /b /c:"done PASS" "%V%\opus1373gv2i\out\result.txt" >nul 2>&1 || (echo 1373I PROBE16 exit 1 at %TIME%, not run: GV2 did not pass >> "%L%" & goto done)
findstr /b /c:"done PASS" "%V%\opus1373gw4i\out\result.txt" >nul 2>&1 || (echo 1373I PROBE16 exit 1 at %TIME%, not run: GW4 did not pass >> "%L%" & goto done)
call "%V%\OPUS1373I_PROBE16.bat"
:done
echo all done %DATE% %TIME% >> "%L%"
exit /b 0