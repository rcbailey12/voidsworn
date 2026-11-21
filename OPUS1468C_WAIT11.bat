@echo off
title GPU line: 1468 shader SHADER3 (after 1121 motion clips N) - WAIT11
rem Board, Nov 21 12:11 UTC (hold lifted after cleanup 2 on Ryan's OK): waits for "OPUS1121N_MOTION exit" in opus1121motn_wait.txt (WAIT11, Board Nov 21 15:19 UTC), runs wait1468c\OPUS1468_SHADER3.bat (sha256 2ad64b9f, unedited; JOB opus1468).
rem End line "OPUS1468_SHADER3 exit". Writes opus1468c_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1468c_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1468"
echo OPUS1468C_WAIT11.bat waiting for OPUS1121N_MOTION exit in opus1121motn_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1121N_MOTION exit" "%V%\opus1121motn_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1468" mkdir "%V%\opus1468"
set "B=%V%\board1119\OPUS1468C_WAIT11_out_before.txt"
dir /b /ad "%V%\opus1468\out_*" > "%B%" 2>nul
echo OPUS1468_SHADER3 start %TIME% >> "%L%"
call "%V%\wait1468c\OPUS1468_SHADER3.bat" > "%V%\opus1468\shader3_console.txt" 2>&1
echo OPUS1468_SHADER3 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1468 >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0
