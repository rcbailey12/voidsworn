@echo off
title GPU line: 1448 sound proof SND1C (after 1434 LOAD14, before 1466 RUN3) - WAIT2 after the 1413f publish hold
rem Board, Nov 21 23:19 UTC: waits for "OPUS1434_LOAD14 exit" in opus1434n_wait.txt, runs wait1448\OPUS1448_SND1C.bat (inbox 98f0310f, sha256 2342c6ca, unedited; JOB opus1448 - a fresh out_* attempt beside SND1B's, which is kept; pin c102aec6 = board/pin-1448c).
rem End line "OPUS1448_SND1C exit". Writes opus1448c_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1448c_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1448"
echo OPUS1448C_WAIT2.bat waiting for OPUS1434_LOAD14 exit in opus1434n_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1434_LOAD14 exit" "%V%\opus1434n_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1448" mkdir "%V%\opus1448"
set "B=%V%\board1119\OPUS1448C_WAIT2_out_before.txt"
dir /b /ad "%V%\opus1448\out_*" > "%B%" 2>nul
echo OPUS1448_SND1C start %TIME% >> "%L%"
call "%V%\wait1448\OPUS1448_SND1C.bat" > "%V%\opus1448\snd1c_console.txt" 2>&1
echo OPUS1448_SND1C exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1448 >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0