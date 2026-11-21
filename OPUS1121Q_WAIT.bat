@echo off
title GPU line: 1121 small deaths Q (after 1121P, before 1466 RUN3)
rem Board, Nov 21 21:41 UTC: waits for "OPUS1121P_MOTION exit" in opus1121motp_wait.txt, runs wait1121motq\OPUS1121Q_small_deaths.bat (inbox 69966f4e, sha256 4bb6f770, unedited; JOB opus1121motq, pin b9de518b = board/pin-1121q).
rem End line "OPUS1121Q_DEATHS exit". Writes opus1121motq_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1121motq_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1121"
echo OPUS1121Q_WAIT.bat waiting for OPUS1121P_MOTION exit in opus1121motp_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1121P_MOTION exit" "%V%\opus1121motp_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1121motq" mkdir "%V%\opus1121motq"
set "B=%V%\board1119\OPUS1121Q_WAIT_out_before.txt"
dir /b /ad "%V%\opus1121motq\out_*" > "%B%" 2>nul
echo OPUS1121Q_DEATHS start %TIME% >> "%L%"
call "%V%\wait1121motq\OPUS1121Q_small_deaths.bat" > "%V%\opus1121motq\deaths_console.txt" 2>&1
echo OPUS1121Q_DEATHS exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1121motq >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0