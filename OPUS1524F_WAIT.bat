@echo off
title GPU line: 1524 ram and boarding shots SHOTS3 (after 1434 LOAD12, before 1121N)
rem Board, Nov 21 18:27 UTC: waits for "OPUS1434_LOAD12 exit" in opus1434l_wait.txt, confirms ffmpeg -version runs, then runs wait1524f\OPUS1524_SHOTS3.bat (inbox 64ef7801, sha256 f279a5d9, unedited; JOB opus1524c, NEW 4f143f1a = board/pin-1524new3, OLD 0a9fe7c0 = board/pin-1524old2).
rem End line "OPUS1524_SHOTS5 exit". Writes opus1524f_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1524f_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1524"
echo OPUS1524F_WAIT.bat waiting for OPUS1434_LOAD12 exit in opus1434l_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1434_LOAD12 exit" "%V%\opus1434l_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
"%V%\ffmpeg\bin\ffmpeg.exe" -hide_banner -version > "%V%\board1119\OPUS1524F_ffmpeg_check.txt" 2>&1
if errorlevel 1 (
  echo ffmpeg -version FAILED, SHOTS3 not run %TIME% >> "%L%"
  echo OPUS1524_SHOTS5 exit 9 at %TIME% ^(ffmpeg check failed, not run^) >> "%L%"
  echo all done %DATE% %TIME% >> "%L%"
  exit /b 0
)
echo ffmpeg -version ok %TIME% >> "%L%"
if not exist "%V%\opus1524c" mkdir "%V%\opus1524c"
set "B=%V%\board1119\OPUS1524F_WAIT_out_before.txt"
dir /b /ad "%V%\opus1524c\out_*" > "%B%" 2>nul
echo OPUS1524_SHOTS5 start %TIME% >> "%L%"
call "%V%\wait1524f\OPUS1524_SHOTS3.bat" > "%V%\opus1524c\shots3_console.txt" 2>&1
echo OPUS1524_SHOTS5 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1524c >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0