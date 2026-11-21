@echo off
title GPU line: 1434 load bench LOAD13 (after 1121O, before 1466 RUN3)
rem Board, Nov 21 21:16 UTC: waits for "OPUS1121O_MOTION exit" in opus1121moto_wait.txt, runs wait1434m\OPUS1434_LOAD13.bat (inbox 8360d6d0, sha256 c24fcbc9, unedited; JOB opus1434m, pin 1a8c7b97 = board/pin-1434m; GPU solo). No publish while it runs.
rem End line "OPUS1434_LOAD13 exit". Writes opus1434m_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1434m_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1434"
echo OPUS1434M_WAIT.bat waiting for OPUS1121O_MOTION exit in opus1121moto_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1121O_MOTION exit" "%V%\opus1121moto_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1434m" mkdir "%V%\opus1434m"
set "B=%V%\board1119\OPUS1434M_WAIT_out_before.txt"
dir /b /ad "%V%\opus1434m\out_*" > "%B%" 2>nul
echo OPUS1434_LOAD13 start %TIME% >> "%L%"
call "%V%\wait1434m\OPUS1434_LOAD13.bat" > "%V%\opus1434m\load13_console.txt" 2>&1
echo OPUS1434_LOAD13 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1434m >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0