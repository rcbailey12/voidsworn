@echo off
title GPU line: 1121 motion clips N (after 1524 SHOTS3) - WAIT11
rem Board, Nov 21 15:19 UTC: waits for "OPUS1524_SHOTS5 exit" in opus1524f_wait.txt (WAIT11, Board Nov 21 18:27 UTC), runs wait1121motn\OPUS1121N_motion_clips.bat (inbox b4f9dcef, sha256 4b8bc251, unedited; JOB opus1121motn, pin 3e635000 = board/pin-1121motn).
rem End line "OPUS1121N_MOTION exit". Writes opus1121motn_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1121motn_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1121"
echo OPUS1121N_WAIT11.bat waiting for OPUS1524_SHOTS5 exit in opus1524f_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1524_SHOTS5 exit" "%V%\opus1524f_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1121motn" mkdir "%V%\opus1121motn"
set "B=%V%\board1119\OPUS1121N_WAIT11_out_before.txt"
dir /b /ad "%V%\opus1121motn\out_*" > "%B%" 2>nul
echo OPUS1121N_MOTION start %TIME% >> "%L%"
call "%V%\wait1121motn\OPUS1121N_motion_clips.bat" > "%V%\opus1121motn\motion_console.txt" 2>&1
echo OPUS1121N_MOTION exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1121motn >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0
