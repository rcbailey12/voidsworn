@echo off
title GPU line: 1536 hold beacon proof A (end of the line, after 1121R)
rem Board, Nov 22 00:34 UTC: waits for "OPUS1121R_DEATHS exit" in opus1121motr_wait.txt, runs wait1536a\OPUS1536A.bat (inbox d17bfafb, sha256 db735831, unedited; JOB opus1536a, NEW 89de211d = board/pin-1536a, OLD c36c156c = main; OJ_NEED_HULLS=O3_11).
rem End line "OPUS1536A exit". Writes opus1536a_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1536a_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1536"
echo OPUS1536A_WAIT.bat waiting for OPUS1121R_DEATHS exit in opus1121motr_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1121R_DEATHS exit" "%V%\opus1121motr_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1536a" mkdir "%V%\opus1536a"
set "B=%V%\board1119\OPUS1536A_WAIT_out_before.txt"
dir /b /ad "%V%\opus1536a\out_*" > "%B%" 2>nul
echo OPUS1536A start %TIME% >> "%L%"
call "%V%\wait1536a\OPUS1536A.bat" > "%V%\opus1536a\proofa_console.txt" 2>&1
echo OPUS1536A exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1536a >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0