@echo off
title GPU line: 1529 cleanup proof 3
rem Board, Nov 21 16:58 UTC: replaces OPUS1529B_WAIT (proof 2, stopped while only waiting). Waits for "OPUS1531_RUN2 exit" in opus1531b_wait.txt, runs wait1529c\OPUS1529_CLEANUP_PROOF3.bat (inbox 1f274771, sha256 399265c1, unedited; JOB opus1529c, pin 80dca8da = board/pin-1529c).
rem End line "OPUS1529_PROOF3 exit". Writes opus1529c_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1529c_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1529"
echo OPUS1529C_WAIT.bat waiting for OPUS1531_RUN2 exit in opus1531b_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1531_RUN2 exit" "%V%\opus1531b_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1529c" mkdir "%V%\opus1529c"
set "B=%V%\board1119\OPUS1529C_WAIT_out_before.txt"
dir /b /ad "%V%\opus1529c\out_*" > "%B%" 2>nul
echo OPUS1529_PROOF3 start %TIME% >> "%L%"
call "%V%\wait1529c\OPUS1529_CLEANUP_PROOF3.bat" > "%V%\opus1529c\proof3_console.txt" 2>&1
echo OPUS1529_PROOF3 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1529c >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0