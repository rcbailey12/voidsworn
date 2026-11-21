@echo off
title Lane C: 1497 selftest 4 (pre-merge head from e89e33e7) (Board, Nov 21)
rem Board, Nov 21 14:54 UTC (inbox 40cf3598): starts at once (keys on the existing "OPUS1497_SELFTEST3 exit" line), then runs wait1497d\OPUS1497_SELFTEST4.bat (sha256 9e73c6f4, unedited) with
rem OPUS_JOB_HEAD set to the read-only copy of tools\pc at e89e33e7 (board1119\prehead1497d\tools\pc\jobs\opus_job_head.bat) and OPUS_JOB_HEAD_PREMERGE=1. End line "OPUS1497_SELFTEST4 exit". Writes opus1497d_wait.txt. Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1497d_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_ISSUE=1497"
set "OPUS_JOB_HEAD=%V%\board1119\prehead1497d\tools\pc\jobs\opus_job_head.bat"
set "OPUS_JOB_HEAD_PREMERGE=1"
echo OPUS1497ST4_RUN.bat waiting for OPUS1497_SELFTEST3 exit in opus1497c_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1497_SELFTEST3 exit" "%V%\opus1497c_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1497st4" mkdir "%V%\opus1497st4"
set "B=%V%\board1119\opus1497st4_out_before.txt"
dir /b /ad "%V%\opus1497st4\out_*" > "%B%" 2>nul
echo OPUS1497_SELFTEST4 start %TIME% >> "%L%"
call "%V%\wait1497d\OPUS1497_SELFTEST4.bat" > "%V%\opus1497st4\selftest4_console.txt" 2>&1
echo OPUS1497_SELFTEST4 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1497st4 >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0