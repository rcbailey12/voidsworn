@echo off
title GPU line: 1531 launch run 4 (replaces RUN3; after 1524 SHOTS2 rerun, before 1434 LOAD12)
rem Board, Nov 21 18:14 UTC: replaces OPUS1531C_WAIT (RUN3, stopped while only waiting). Waits for "OPUS1524_SHOTS4 exit" in opus1524e_wait.txt, runs wait1531d\OPUS1531_LAUNCH_RUN4.bat (inbox 5506fbb5, sha256 87923a8f, unedited; JOB opus1531d, pin 0c723f3a = board/pin-1531d).
rem End line kept as "OPUS1531_RUN3 exit" in opus1531c_wait.txt so OPUS1434L_WAIT stays valid; in that log it means RUN4. Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1531c_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1531"
echo OPUS1531D_WAIT.bat waiting for OPUS1524_SHOTS4 exit in opus1524e_wait.txt %DATE% %TIME% (runs RUN4; its end line below is named OPUS1531_RUN3 by Board ruling) >> "%L%"
:wait
findstr /b /c:"OPUS1524_SHOTS4 exit" "%V%\opus1524e_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1531d" mkdir "%V%\opus1531d"
set "B=%V%\board1119\OPUS1531D_WAIT_out_before.txt"
dir /b /ad "%V%\opus1531d\out_*" > "%B%" 2>nul
echo OPUS1531_RUN4 start %TIME% >> "%L%"
call "%V%\wait1531d\OPUS1531_LAUNCH_RUN4.bat" > "%V%\opus1531d\run4_console.txt" 2>&1
echo OPUS1531_RUN3 exit %ERRORLEVEL% at %TIME% (this is RUN4) >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1531d >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0