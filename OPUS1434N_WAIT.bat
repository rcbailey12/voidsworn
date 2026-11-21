@echo off
title GPU line: 1434 load bench LOAD14 (after 1448 SND1B, before 1466 RUN3)
rem Board, Nov 21 23:04 UTC: waits for "OPUS1448_SND1B exit" in opus1448_wait.txt, runs wait1434n\OPUS1434_LOAD14.bat (inbox 4049fb64, sha256 f0b0230a, unedited; JOB opus1434n, pin bb32280a = board/pin-1434n; GPU solo). No publish while it runs.
rem End line "OPUS1434_LOAD14 exit". Writes opus1434n_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1434n_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1434"
echo OPUS1434N_WAIT.bat waiting for OPUS1448_SND1B exit in opus1448_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1448_SND1B exit" "%V%\opus1448_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1434n" mkdir "%V%\opus1434n"
set "B=%V%\board1119\OPUS1434N_WAIT_out_before.txt"
dir /b /ad "%V%\opus1434n\out_*" > "%B%" 2>nul
echo OPUS1434_LOAD14 start %TIME% >> "%L%"
call "%V%\wait1434n\OPUS1434_LOAD14.bat" > "%V%\opus1434n\load14_console.txt" 2>&1
echo OPUS1434_LOAD14 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1434n >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0