@echo off
title Lane C: 1535 TEMP proof (code only, not elevated) (Board, Nov 21)
rem Board, Nov 21 16:23 UTC (inbox b1af0375): waits (60 s steps) for "OPUS1497_AFTERRELAY4 exit" in opus1497d_wait.txt (end of 1497 pair 4), then runs wait1535\OPUS1535_TEMP_PROOF.bat (sha256 0b3e69ca, unedited; JOB opus1535, pin 9c5e2124 = board/pin-1535) not elevated. End line "OPUS1535_TEMP_PROOF exit". Writes opus1535_wait.txt. Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1535_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_ISSUE=1535"
echo OPUS1535_RUN.bat waiting for OPUS1497_AFTERRELAY4 exit in opus1497d_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1497_AFTERRELAY4 exit" "%V%\opus1497d_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1535" mkdir "%V%\opus1535"
set "B=%V%\board1119\opus1535_out_before.txt"
dir /b /ad "%V%\opus1535\out_*" > "%B%" 2>nul
echo OPUS1535_TEMP_PROOF start %DATE% %TIME% >> "%L%"
call "%V%\wait1535\OPUS1535_TEMP_PROOF.bat" > "%V%\opus1535\proof_console.txt" 2>&1
echo OPUS1535_TEMP_PROOF exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1535 >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0