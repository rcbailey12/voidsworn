@echo off
rem Board, Nov 21: runs wait1497d\OPUS1497_AFTERRELAY4.bat (sha256 967ee28b, unedited) with the same pre-merge head env as SELFTEST4 (e89e33e7), argument board/pc-out-1497st4. It deletes only inside opus1497st4 and opus1497st4ship.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "OPUS_JOB_HEAD=%V%\board1119\prehead1497d\tools\pc\jobs\opus_job_head.bat"
set "OPUS_JOB_HEAD_PREMERGE=1"
call "%V%\wait1497d\OPUS1497_AFTERRELAY4.bat" board/pc-out-1497st4 > "%V%\opus1497st4\afterrelay4_console.txt" 2>&1
echo OPUS1497_AFTERRELAY4 exit %ERRORLEVEL% at %TIME% >> "%V%\opus1497d_wait.txt"
exit /b 0