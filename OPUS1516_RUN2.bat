@echo off
title Lane C: 1516 collect proof, try 2 with PIL_PYTHON set (Board, Nov 21)
rem Board, Nov 21 14:08 UTC: runs wait1516\OPUS1516_COLLECT_PROOF.bat (inbox 7b89981b, sha256 4b9d62d2, unedited; JOB opus1516, pin 0fbb59a7 = board/pin-1516b) at once, in its own checkout; nothing installed.
rem End line "OPUS1516_COLLECT_PROOF exit". Writes opus1516_wait.txt. Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1516_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_ISSUE=1516"
rem try 2: try 1 stopped at the preflight ("MISSING pil: set PIL_PYTHON"); this wrapper sets PIL_PYTHON to the PC's real Python 3.12 (PIL 13.0.0). The job bat is unedited.
set "PIL_PYTHON=C:\Users\rcbai\AppData\Local\Programs\Python\Python312\python.exe"
if not exist "%V%\opus1516" mkdir "%V%\opus1516"
set "B=%V%\board1119\opus1516_try2_out_before.txt"
dir /b /ad "%V%\opus1516\out_*" > "%B%" 2>nul
echo OPUS1516_COLLECT_PROOF try 2 start %DATE% %TIME% >> "%L%"
call "%V%\wait1516\OPUS1516_COLLECT_PROOF.bat" > "%V%\opus1516\proof_console.txt" 2>&1
echo OPUS1516_COLLECT_PROOF exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1516 >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0