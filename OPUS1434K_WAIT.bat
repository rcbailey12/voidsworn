@echo off
title GPU line: 1434 load bench LOAD11 (after 1524 SHOTS2, before 1121N)
rem Board, Nov 21 17:11 UTC (replaces OPUS1434J_WAIT / LOAD10): waits for "OPUS1524_SHOTS3 exit" in opus1524c_wait.txt, runs wait1434k\OPUS1434_LOAD11.bat (inbox 80823a82, sha256 72530000, unedited; JOB opus1434k, pin 5a0dffb2 = board/pin-1434k; GPU solo). No publish while it runs.
rem End line "OPUS1434_LOAD11 exit". Writes opus1434k_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1434k_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1434"
echo OPUS1434K_WAIT.bat waiting for OPUS1524_SHOTS3 exit in opus1524c_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1524_SHOTS3 exit" "%V%\opus1524c_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1434k" mkdir "%V%\opus1434k"
set "B=%V%\board1119\OPUS1434K_WAIT_out_before.txt"
dir /b /ad "%V%\opus1434k\out_*" > "%B%" 2>nul
echo OPUS1434_LOAD11 start %TIME% >> "%L%"
call "%V%\wait1434k\OPUS1434_LOAD11.bat" > "%V%\opus1434k\load11_console.txt" 2>&1
echo OPUS1434_LOAD11 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1434k >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0