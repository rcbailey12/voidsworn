@echo off
title GPU line: 1121 motion clips P (final, side, back, long; after 1434 LOAD13, before 1466 RUN3) - WAIT2 after the C14 K publish hold
rem Board, Nov 21 21:37 UTC: waits for "OPUS1434_LOAD13 exit" in opus1434m_wait.txt, runs wait1121motp\OPUS1121P_motion_clips.bat (inbox 98795550, sha256 0314905d, unedited; JOB opus1121motp, pin 434ab1fa = board/pin-1121p; GPU solo).
rem End line "OPUS1121P_MOTION exit". Writes opus1121motp_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1121motp_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1121"
echo OPUS1121P_WAIT2.bat waiting for OPUS1434_LOAD13 exit in opus1434m_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1434_LOAD13 exit" "%V%\opus1434m_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1121motp" mkdir "%V%\opus1121motp"
set "B=%V%\board1119\OPUS1121P_WAIT2_out_before.txt"
dir /b /ad "%V%\opus1121motp\out_*" > "%B%" 2>nul
echo OPUS1121P_MOTION start %TIME% >> "%L%"
call "%V%\wait1121motp\OPUS1121P_motion_clips.bat" > "%V%\opus1121motp\motion_console.txt" 2>&1
echo OPUS1121P_MOTION exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1121motp >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0