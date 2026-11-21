@echo off
title GPU line: 1448 sound proof SND1B (after 1121Q, before 1466 RUN3) - WAIT2 after the 1415H publish hold
rem Board, Nov 21 22:30 UTC: never ran on this PC (no opus1448). Waits for "OPUS1121Q_DEATHS exit" in opus1121motq_wait.txt, runs wait1448\OPUS1448_SND1B.bat (inbox 9384c938, sha256 92ef60be, unedited; JOB opus1448, pin 08e42437 = board/pin-1448).
rem End line "OPUS1448_SND1B exit". Writes opus1448_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1448_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1448"
echo OPUS1448_WAIT2.bat waiting for OPUS1121Q_DEATHS exit in opus1121motq_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1121Q_DEATHS exit" "%V%\opus1121motq_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1448" mkdir "%V%\opus1448"
set "B=%V%\board1119\OPUS1448_WAIT2_out_before.txt"
dir /b /ad "%V%\opus1448\out_*" > "%B%" 2>nul
echo OPUS1448_SND1B start %TIME% >> "%L%"
call "%V%\wait1448\OPUS1448_SND1B.bat" > "%V%\opus1448\snd1b_console.txt" 2>&1
echo OPUS1448_SND1B exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1448 >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0