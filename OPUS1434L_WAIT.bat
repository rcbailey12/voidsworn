@echo off
title GPU line: 1434 load bench LOAD12 (after 1531 RUN3, before 1121N)
rem Board, Nov 21 18:10 UTC: waits for "OPUS1531_RUN3 exit" in opus1531c_wait.txt, runs wait1434l\OPUS1434_LOAD12.bat (inbox da7b0cea, sha256 61988bc2, unedited; JOB opus1434l, pin dc4ddbf7 = board/pin-1434l; GPU solo). No publish while it runs.
rem End line "OPUS1434_LOAD12 exit". Writes opus1434l_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1434l_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1434"
echo OPUS1434L_WAIT.bat waiting for OPUS1531_RUN3 exit in opus1531c_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1531_RUN3 exit" "%V%\opus1531c_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1434l" mkdir "%V%\opus1434l"
set "B=%V%\board1119\OPUS1434L_WAIT_out_before.txt"
dir /b /ad "%V%\opus1434l\out_*" > "%B%" 2>nul
echo OPUS1434_LOAD12 start %TIME% >> "%L%"
call "%V%\wait1434l\OPUS1434_LOAD12.bat" > "%V%\opus1434l\load12_console.txt" 2>&1
echo OPUS1434_LOAD12 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1434l >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0