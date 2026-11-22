@echo off
title GPU line: 1235 first-hit damage look bench - WAIT3 (after 1434 LOAD15; 1143 REC1 dropped)
rem Board, Nov 21 14:55 UTC (inbox 2f868bec): waits for "OPUS1434_LOAD15 exit" in opus1434o_wait.txt (WAIT3, Board Nov 22 00:30 UTC: LOAD15 slotted after MEASURE4), runs wait1235\OPUS1235_FIRSTHIT.bat (sha256 ab1626e8, unedited; JOB opus1235, NEW 721d4f88 = board/pin-1235b, OLD 624796c5). Its fresh out_<time> attempt sits beside the Nov 19 contents of opus1235, which stay untouched.
rem End line "OPUS1235_FIRSTHIT exit". Writes opus1235_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1235_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1235"
echo OPUS1235_WAIT3.bat waiting for OPUS1434_LOAD15 exit in opus1434o_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1434_LOAD15 exit" "%V%\opus1434o_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1235" mkdir "%V%\opus1235"
set "B=%V%\board1119\OPUS1235_WAIT3_out_before.txt"
dir /b /ad "%V%\opus1235\out_*" > "%B%" 2>nul
echo OPUS1235_FIRSTHIT start %TIME% >> "%L%"
call "%V%\wait1235\OPUS1235_FIRSTHIT.bat" > "%V%\opus1235\firsthit_console.txt" 2>&1
echo OPUS1235_FIRSTHIT exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1235 >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0
