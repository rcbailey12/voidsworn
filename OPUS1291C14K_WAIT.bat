@echo off
title Ship line: 1291 Chorus C14 run K (moving flesh doors) after CM4 (1413e), replaces C14 J (sheet first, no publish)
rem Board, Nov 21 20:21 UTC (Ryan "Cool go"; inbox e418a3c5, folder 1291k): waits for "1413 H10E exit" in chain_1119cm.txt (end of CM4), runs wait1291c14k\OPUS1291_C14_K.bat (sha256 dff390ae, unedited; JOB opus1291c14k, chorus_C14 B22_11, board/pin-1543-doors1 4a73ba3a, pin already in repo-mirror.git).
rem End line "1291 C14K exit". Writes opus1291c14k_wait.txt (appends). Never deletes. Trial only, no publish.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1291c14k_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
echo OPUS1291C14K_WAIT.bat waiting for 1413 H10E exit in chain_1119cm.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"1413 H10E exit" "%V%\chain_1119cm.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
echo 1291 C14K start %TIME% >> "%L%"
setlocal & set "PIN=" & set "PUBLISH=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "SHIP=" & set "CODE=" & set "BRANCH=" & set "JOB_DIR=" & set "FACS=" & set "PC_GPU_ISSUE=1291" & call "%V%\wait1291c14k\OPUS1291_C14_K.bat" & endlocal
echo 1291 C14K exit %ERRORLEVEL% at %TIME% >> "%L%"
echo all done %DATE% %TIME% >> "%L%"
exit /b 0