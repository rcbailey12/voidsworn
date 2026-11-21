@echo off
rem Board, Nov 21: runs wait1497c\OPUS1497_AFTERRELAY3.bat (sha256 223a0798, unedited) with the same pre-merge head env as SELFTEST3 (3f5041c5), argument board/pc-out-1497st3. It deletes only inside opus1497st3 and opus1497st3ship.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "OPUS_JOB_HEAD=%V%\board1119\prehead1497c\tools\pc\jobs\opus_job_head.bat"
set "OPUS_JOB_HEAD_PREMERGE=1"
call "%V%\wait1497c\OPUS1497_AFTERRELAY3.bat" board/pc-out-1497st3 > "%V%\opus1497st3\afterrelay3_console.txt" 2>&1
echo OPUS1497_AFTERRELAY3 exit %ERRORLEVEL% at %TIME% >> "%V%\opus1497c_wait.txt"
exit /b 0