@echo off
title GPU line: 1531 launch run 2
rem Board, Nov 21 15:48 UTC: waits for "OPUS1524_SHOTS exit" in opus1524_wait.txt, runs wait1531b\OPUS1531_LAUNCH_RUN2.bat (inbox b68d7341, sha256 f098eb75, unedited; JOB opus1531b, pin 66f92ba6 = board/pin-1531b). RUN1 (opus1531a) was never queued.
rem End line "OPUS1531_RUN2 exit". Writes opus1531b_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1531b_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1531"
echo OPUS1531B_WAIT.bat waiting for OPUS1524_SHOTS exit in opus1524_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1524_SHOTS exit" "%V%\opus1524_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1531b" mkdir "%V%\opus1531b"
set "B=%V%\board1119\OPUS1531B_WAIT_out_before.txt"
dir /b /ad "%V%\opus1531b\out_*" > "%B%" 2>nul
echo OPUS1531_RUN2 start %TIME% >> "%L%"
call "%V%\wait1531b\OPUS1531_LAUNCH_RUN2.bat" > "%V%\opus1531b\run2_console.txt" 2>&1
echo OPUS1531_RUN2 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1531b >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0
