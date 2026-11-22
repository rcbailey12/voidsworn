@echo off
title GPU line: 1121 small deaths close R (after 1448 SND1G) - WAIT2
rem Board, Nov 21 22:50 UTC: waits for "OPUS1448_SND1G exit" in opus1448g_wait.txt (WAIT2, Board Nov 22 00:43 UTC: SND1G slotted after FIRSTHIT), runs wait1121motr\OPUS1121R_small_deaths_close.bat (inbox 53810138, sha256 d67c5f48, unedited; JOB opus1121motr, pin 53f4b64f = board/pin-1121r).
rem End line "OPUS1121R_DEATHS exit". Writes opus1121motr_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1121motr_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1121"
echo OPUS1121R_WAIT2.bat waiting for OPUS1448_SND1G exit in opus1448g_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1448_SND1G exit" "%V%\opus1448g_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1121motr" mkdir "%V%\opus1121motr"
set "B=%V%\board1119\OPUS1121R_WAIT2_out_before.txt"
dir /b /ad "%V%\opus1121motr\out_*" > "%B%" 2>nul
echo OPUS1121R_DEATHS start %TIME% >> "%L%"
call "%V%\wait1121motr\OPUS1121R_small_deaths_close.bat" > "%V%\opus1121motr\deaths_console.txt" 2>&1
echo OPUS1121R_DEATHS exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1121motr >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0