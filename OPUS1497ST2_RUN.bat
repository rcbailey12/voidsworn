@echo off
title Lane C: 1497 selftest part 1 (pre-merge head from 1136cf78) (Board, Nov 21)
rem Board, Nov 21 14:39 UTC: runs wait1497\OPUS1497_SELFTEST2.bat (inbox 6395b951, sha256 5d9e4c1b, unedited) with OPUS_JOB_HEAD set to the read-only copy of tools\pc at 1136cf78
rem (board1119\prehead1497\tools\pc\jobs\opus_job_head.bat) and OPUS_JOB_HEAD_PREMERGE=1. Headless import only, no rendering. End line "OPUS1497_SELFTEST2 exit". Writes opus1497_wait.txt. Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1497_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_ISSUE=1497"
set "OPUS_JOB_HEAD=%V%\board1119\prehead1497\tools\pc\jobs\opus_job_head.bat"
set "OPUS_JOB_HEAD_PREMERGE=1"
if not exist "%V%\opus1497st2" mkdir "%V%\opus1497st2"
set "B=%V%\board1119\opus1497st2_out_before.txt"
dir /b /ad "%V%\opus1497st2\out_*" > "%B%" 2>nul
echo OPUS1497_SELFTEST2 start %DATE% %TIME% >> "%L%"
call "%V%\wait1497\OPUS1497_SELFTEST2.bat" > "%V%\opus1497st2\selftest2_console.txt" 2>&1
echo OPUS1497_SELFTEST2 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1497st2 >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0