@echo off
rem Board, Nov 21: runs wait1497\OPUS1497_AFTERRELAY2.bat (sha256 f3194508, unedited) with the same pre-merge head env as SELFTEST2, argument board/pc-out-1497st2. It deletes only inside opus1497st2 and opus1497st2ship (the job's own test leftovers).
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "OPUS_JOB_HEAD=%V%\board1119\prehead1497\tools\pc\jobs\opus_job_head.bat"
set "OPUS_JOB_HEAD_PREMERGE=1"
call "%V%\wait1497\OPUS1497_AFTERRELAY2.bat" board/pc-out-1497st2 > "%V%\opus1497st2\afterrelay2_console.txt" 2>&1
echo OPUS1497_AFTERRELAY2 exit %ERRORLEVEL% at %TIME% >> "%V%\opus1497_wait.txt"
exit /b 0