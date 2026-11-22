@echo off
title GPU line: 1434 load bench LOAD15 (after 1439 MEASURE4, before 1235 FIRSTHIT)
rem Board, Nov 22 00:30 UTC: waits for "OPUS1439_MEASURE4 exit" in opus1439d_wait.txt, runs wait1434o\OPUS1434_LOAD15.bat (inbox f66a546c, sha256 277e657a, unedited; JOB opus1434o, pin 5c78f326 = board/pin-1434o; GPU solo). No publish while it runs.
rem End line "OPUS1434_LOAD15 exit". Writes opus1434o_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1434o_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1434"
echo OPUS1434O_WAIT.bat waiting for OPUS1439_MEASURE4 exit in opus1439d_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1439_MEASURE4 exit" "%V%\opus1439d_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1434o" mkdir "%V%\opus1434o"
set "B=%V%\board1119\OPUS1434O_WAIT_out_before.txt"
dir /b /ad "%V%\opus1434o\out_*" > "%B%" 2>nul
echo OPUS1434_LOAD15 start %TIME% >> "%L%"
call "%V%\wait1434o\OPUS1434_LOAD15.bat" > "%V%\opus1434o\load15_console.txt" 2>&1
echo OPUS1434_LOAD15 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1434o >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0