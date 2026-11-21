@echo off
title GPU line: 1524 ram and boarding shots SHOTS2 (after 1529 proof 3)
rem Board, Nov 21 16:33 UTC: replaces OPUS1524C_WAIT (Board Nov 21 16:58 UTC: proof 2 replaced by proof 3; C replaced OPUS1524B_WAIT). Waits for "OPUS1529_PROOF3 exit" in opus1529c_wait.txt, runs wait1524c\OPUS1524_SHOTS2.bat (inbox 2b4c54d9, sha256 34693dda, unedited; JOB opus1524b, NEW 3ea515ef = board/pin-1524new2, OLD 0a9fe7c0 = board/pin-1524old2).
rem End line "OPUS1524_SHOTS3 exit". Writes opus1524c_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1524c_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1524"
echo OPUS1524D_WAIT.bat waiting for OPUS1529_PROOF3 exit in opus1529c_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1529_PROOF3 exit" "%V%\opus1529c_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1524b" mkdir "%V%\opus1524b"
set "B=%V%\board1119\OPUS1524D_WAIT_out_before.txt"
dir /b /ad "%V%\opus1524b\out_*" > "%B%" 2>nul
echo OPUS1524_SHOTS3 start %TIME% >> "%L%"
call "%V%\wait1524c\OPUS1524_SHOTS2.bat" > "%V%\opus1524b\shots2_console.txt" 2>&1
echo OPUS1524_SHOTS3 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1524b >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0