@echo off
title Ship line: 1415G GS1b rerun (stamps carry the dirty list) after 1415G GA1
rem Board, Nov 21 18:09 UTC (inbox 6cad0d4b): waits for "1415G GA1 exit" in chain_1119cn.txt, runs wait1415g\OPUS1415G_GS1B_RUN.bat (sha256 64a51b50, unedited; JOB opus1415g_GS1b, ithar_GS1 I14_23, board/pin-1415g 5d7a6ce5).
rem End line "1415G GS1B exit". Writes opus1415gs1b_wait.txt (appends). Never deletes. Trial only, no publish.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1415gs1b_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
echo OPUS1415GS1B_WAIT.bat waiting for 1415G GA1 exit in chain_1119cn.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"1415G GA1 exit" "%V%\chain_1119cn.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
echo 1415G GS1B start %TIME% >> "%L%"
setlocal & set "PIN=" & set "PUBLISH=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "SHIP=" & set "CODE=" & set "BRANCH=" & set "JOB_DIR=" & set "FACS=" & set "PC_GPU_ISSUE=1415" & call "%V%\wait1415g\OPUS1415G_GS1B_RUN.bat" & endlocal
echo 1415G GS1B exit %ERRORLEVEL% at %TIME% >> "%L%"
echo all done %DATE% %TIME% >> "%L%"
exit /b 0