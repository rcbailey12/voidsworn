@echo off
title GPU line: 1448 sound proof SND1G (after 1235 FIRSTHIT, before 1121R)
rem Board, Nov 22 00:43 UTC: waits for "OPUS1235_FIRSTHIT exit" in opus1235_wait.txt, runs wait1448g\OPUS1448_SND1G.bat (inbox 569271ef, sha256 b104872b, unedited; JOB opus1448g, pin 1cc09be0 = board/pin-1448g). SND1E and SND1F are superseded and not run.
rem End line "OPUS1448_SND1G exit". Writes opus1448g_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1448g_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1448"
echo OPUS1448G_WAIT.bat waiting for OPUS1235_FIRSTHIT exit in opus1235_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1235_FIRSTHIT exit" "%V%\opus1235_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
if not exist "%V%\opus1448g" mkdir "%V%\opus1448g"
set "B=%V%\board1119\OPUS1448G_WAIT_out_before.txt"
dir /b /ad "%V%\opus1448g\out_*" > "%B%" 2>nul
echo OPUS1448_SND1G start %TIME% >> "%L%"
call "%V%\wait1448g\OPUS1448_SND1G.bat" > "%V%\opus1448g\snd1g_console.txt" 2>&1
echo OPUS1448_SND1G exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1448g >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0