@echo off
title GPU line: 1466 run 3 (after 1448 SND1C) - WAIT9
rem Board, Nov 21 12:11 UTC (hold lifted after cleanup 2 on Ryan's OK): waits for "OPUS1448_SND1C exit" in opus1448c_wait.txt (WAIT9, Board Nov 21 23:19 UTC: SND1C slotted after LOAD14), runs wait1466c\OPUS1466_RUN3.bat (sha256 078dba7e, unedited; JOB opus1466).
rem End line "OPUS1466_RUN3 exit". Writes opus1466c_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1466c_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1466"
echo OPUS1466C_WAIT9.bat waiting for OPUS1448_SND1C exit in opus1448c_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1448_SND1C exit" "%V%\opus1448c_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1466" mkdir "%V%\opus1466"
set "B=%V%\board1119\OPUS1466C_WAIT9_out_before.txt"
dir /b /ad "%V%\opus1466\out_*" > "%B%" 2>nul
echo OPUS1466_RUN3 start %TIME% >> "%L%"
call "%V%\wait1466c\OPUS1466_RUN3.bat" > "%V%\opus1466\run3_console.txt" 2>&1
echo OPUS1466_RUN3 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1466 >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0
