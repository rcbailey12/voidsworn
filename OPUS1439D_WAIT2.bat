@echo off
title GPU line: 1439 measure 4
rem Board, Nov 21 12:11 UTC (hold lifted after cleanup 2 on Ryan's OK): waits for "OPUS1466_RUN3 exit" in opus1466c_wait.txt, runs wait1439d\OPUS1439_MEASURE4.bat (sha256 d4d1b2bf, unedited; JOB opus1439).
rem End line "OPUS1439_MEASURE4 exit". Writes opus1439d_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1439d_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1439"
echo OPUS1439D_WAIT2.bat waiting for OPUS1466_RUN3 exit in opus1466c_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1466_RUN3 exit" "%V%\opus1466c_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1439" mkdir "%V%\opus1439"
set "B=%V%\board1119\OPUS1439D_WAIT2_out_before.txt"
dir /b /ad "%V%\opus1439\out_*" > "%B%" 2>nul
echo OPUS1439_MEASURE4 start %TIME% >> "%L%"
call "%V%\wait1439d\OPUS1439_MEASURE4.bat" > "%V%\opus1439\measure4_console.txt" 2>&1
echo OPUS1439_MEASURE4 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1439 >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0
