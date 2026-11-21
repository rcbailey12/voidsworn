@echo off
title GPU line: 1373L KF1 size probe PROBE17B (Board, Nov 21)
rem Board, Nov 21 14:45 UTC (inbox 2514a97f): waits (60 s steps) for "OPUS1399_SMALLAFTER exit" in opus1399s_wait.txt, then calls wait1373p17\OPUS1373L_PROBE17B.bat (sha256 cc5a2255, unedited, with
rem probe1373l_prep.ps1 fc92edd3 beside it). The bat writes its own end line "1373L PROBE17 exit" into %L% (this log). Writes opus1373p17_wait.txt. Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1373p17_wait.txt"
set "PC_GPU_WAIT_SECONDS=3600"
echo OPUS1373P17_WAIT.bat waiting for OPUS1399_SMALLAFTER exit in opus1399s_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1399_SMALLAFTER exit" "%V%\opus1399s_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
echo 1373L PROBE17B start %TIME% >> "%L%"
call "%V%\wait1373p17\OPUS1373L_PROBE17B.bat"
findstr /b /c:"1373L PROBE17 exit" "%L%" >nul 2>&1 || echo 1373L PROBE17 exit 9 at %TIME%, the bat ended without its own end line >> "%L%"
echo all done %DATE% %TIME% >> "%L%"
exit /b 0