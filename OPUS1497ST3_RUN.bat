@echo off
title Lane C: 1497 selftest 3 part 1 (pre-merge head from 3f5041c5) (Board, Nov 21)
rem Board, Nov 21 14:54 UTC (inbox f5142c81): waits (60 s steps) for "OPUS1497_SELFTEST2 exit" in opus1497_wait.txt, then runs wait1497c\OPUS1497_SELFTEST3.bat (sha256 f5bbc7b0, unedited) with
rem OPUS_JOB_HEAD set to the read-only copy of tools\pc at 3f5041c5 (board1119\prehead1497c\tools\pc\jobs\opus_job_head.bat) and OPUS_JOB_HEAD_PREMERGE=1. End line "OPUS1497_SELFTEST3 exit". Writes opus1497c_wait.txt. Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1497c_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_ISSUE=1497"
set "OPUS_JOB_HEAD=%V%\board1119\prehead1497c\tools\pc\jobs\opus_job_head.bat"
set "OPUS_JOB_HEAD_PREMERGE=1"
echo OPUS1497ST3_RUN.bat waiting for OPUS1497_SELFTEST2 exit in opus1497_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1497_SELFTEST2 exit" "%V%\opus1497_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1497st3" mkdir "%V%\opus1497st3"
set "B=%V%\board1119\opus1497st3_out_before.txt"
dir /b /ad "%V%\opus1497st3\out_*" > "%B%" 2>nul
echo OPUS1497_SELFTEST3 start %TIME% >> "%L%"
call "%V%\wait1497c\OPUS1497_SELFTEST3.bat" > "%V%\opus1497st3\selftest3_console.txt" 2>&1
echo OPUS1497_SELFTEST3 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1497st3 >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0