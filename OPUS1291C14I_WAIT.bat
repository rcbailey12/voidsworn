@echo off
title Ship line: 1291 Chorus C14 run I after 1415G GS1b (sheet first, no publish)
rem Board, Nov 21 18:09 UTC (inbox 6cad0d4b): waits for "1415G GS1B exit" in opus1415gs1b_wait.txt, refreshes nothing (pin d30dfcef already in repo-mirror.git), runs wait1291c14i\OPUS1291_C14_I.bat (sha256 b0b6cdeb, unedited; JOB opus1291c14i, chorus_C14 B22_11, board/pin-1291-c14holes d30dfcef, stages 3-7).
rem End line "1291 C14I exit". Writes opus1291c14i_wait.txt (appends). Never deletes. Trial only, no publish.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1291c14i_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
echo OPUS1291C14I_WAIT.bat waiting for 1415G GS1B exit in opus1415gs1b_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"1415G GS1B exit" "%V%\opus1415gs1b_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
echo 1291 C14I start %TIME% >> "%L%"
setlocal & set "PIN=" & set "PUBLISH=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "SHIP=" & set "CODE=" & set "BRANCH=" & set "JOB_DIR=" & set "FACS=" & set "PC_GPU_ISSUE=1291" & call "%V%\wait1291c14i\OPUS1291_C14_I.bat" & endlocal
echo 1291 C14I exit %ERRORLEVEL% at %TIME% >> "%L%"
echo all done %DATE% %TIME% >> "%L%"
exit /b 0