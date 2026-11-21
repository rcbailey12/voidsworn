@echo off
title GPU line: 1121 motion clips O (fixed run; after 1468 SHADER3, before 1466 RUN3)
rem Board, Nov 21 20:35 UTC: 1121N superseded (empty run = FAIL). Waits for "OPUS1468_SHADER3 exit" in opus1468c_wait.txt, runs wait1121moto\OPUS1121O_motion_clips.bat (inbox f007619d, sha256 8daaf571, unedited; JOB opus1121moto, pin 5e75a86d = board/pin-1121o; GPU solo).
rem End line "OPUS1121O_MOTION exit". Writes opus1121moto_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1121moto_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1121"
echo OPUS1121O_WAIT.bat waiting for OPUS1468_SHADER3 exit in opus1468c_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1468_SHADER3 exit" "%V%\opus1468c_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1121moto" mkdir "%V%\opus1121moto"
set "B=%V%\board1119\OPUS1121O_WAIT_out_before.txt"
dir /b /ad "%V%\opus1121moto\out_*" > "%B%" 2>nul
echo OPUS1121O_MOTION start %TIME% >> "%L%"
call "%V%\wait1121moto\OPUS1121O_motion_clips.bat" > "%V%\opus1121moto\motion_console.txt" 2>&1
echo OPUS1121O_MOTION exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1121moto >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0