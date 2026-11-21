@echo off
title Ship line: 1539 pre-merge proof (after 1415F GA1, before 1413e CM2)
rem Board, Nov 21 16:54 UTC: waits for "1415F GA1 exit" in chain_1119cl.txt (end of CL2), runs wait1539\OPUS1539_PROOF.bat (inbox a9b350f3, sha256 40cfcc34, unedited; JOB opus1539proof, PIN_1540 a006817a = board/pin-1539) as a pre-merge smoke with the read-only head copy board1119\prehead1539 (git archive of a006817a tools/pc).
rem End line "OPUS1539_PROOF exit". Writes opus1539_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1539_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1539"
set "PIL_PYTHON=%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe"
echo OPUS1539_WAIT.bat waiting for 1415F GA1 exit in chain_1119cl.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"1415F GA1 exit" "%V%\chain_1119cl.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1539proof" mkdir "%V%\opus1539proof"
set "B=%V%\board1119\OPUS1539_WAIT_out_before.txt"
dir /b /ad "%V%\opus1539proof\out_*" > "%B%" 2>nul
set "OPUS_JOB_HEAD=%V%\board1119\prehead1539\tools\pc\jobs\opus_job_head.bat"
set "OPUS_JOB_HEAD_PREMERGE=1"
echo OPUS1539_PROOF start %TIME% >> "%L%"
call "%V%\wait1539\OPUS1539_PROOF.bat" > "%V%\opus1539proof\proof_console.txt" 2>&1
echo OPUS1539_PROOF exit %ERRORLEVEL% at %TIME% >> "%L%"
set "OPUS_JOB_HEAD="
set "OPUS_JOB_HEAD_PREMERGE="
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1539proof >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0