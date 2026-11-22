@echo off
title GPU line: 1434 load bench LOAD17 (end of the line, after 1536A) - WAIT2 after the 1373N publish hold
rem Board, Nov 22 02:05 UTC: waits for "OPUS1536A exit" in opus1536a_wait.txt, runs wait1434r\OPUS1434_LOAD17.bat (inbox 155c6bd9, sha256 e5ab6e6f, unedited; JOB opus1434r, pin 057db2b4 = board/pin-1434r; GPU solo). LOAD16 stays unqueued. No publish while it runs.
rem End line "OPUS1434_LOAD17 exit". Writes opus1434r_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1434r_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1434"
echo OPUS1434R_WAIT2.bat waiting for OPUS1536A exit in opus1536a_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1536A exit" "%V%\opus1536a_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1434r" mkdir "%V%\opus1434r"
set "B=%V%\board1119\OPUS1434R_WAIT2_out_before.txt"
dir /b /ad "%V%\opus1434r\out_*" > "%B%" 2>nul
echo OPUS1434_LOAD17 start %TIME% >> "%L%"
call "%V%\wait1434r\OPUS1434_LOAD17.bat" > "%V%\opus1434r\load17_console.txt" 2>&1
echo OPUS1434_LOAD17 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1434r >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0