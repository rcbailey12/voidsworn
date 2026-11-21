@echo off
title GPU line: 1524 ram and boarding shots SHOTS2 rerun (after 1434 LOAD11, before 1121N)
rem Board, Nov 21 17:29 UTC: SHOTS2 try 1 (OPUS1524D_WAIT, end line OPUS1524_SHOTS3) failed preflight on missing ffmpeg; ffmpeg is now at voidsworn_test\ffmpeg\bin\ffmpeg.exe (copy of imageio_ffmpeg 9.0.2, sha256 3256173f). Waits for "OPUS1434_LOAD11 exit" in opus1434k_wait.txt, confirms ffmpeg -version runs, then runs wait1524c\OPUS1524_SHOTS2.bat (inbox 2b4c54d9, sha256 34693dda, unedited; JOB opus1524b).
rem End line "OPUS1524_SHOTS4 exit". Writes opus1524e_wait.txt (appends). Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1524e_wait.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
set "PC_GPU_ISSUE=1524"
echo OPUS1524E_WAIT.bat waiting for OPUS1434_LOAD11 exit in opus1434k_wait.txt %DATE% %TIME% >> "%L%"
:wait
findstr /b /c:"OPUS1434_LOAD11 exit" "%V%\opus1434k_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
"%V%\ffmpeg\bin\ffmpeg.exe" -hide_banner -version > "%V%\board1119\OPUS1524E_ffmpeg_check.txt" 2>&1
if errorlevel 1 (
  echo ffmpeg -version FAILED, SHOTS2 not run %TIME% >> "%L%"
  echo OPUS1524_SHOTS4 exit 9 at %TIME% ^(ffmpeg check failed, not run^) >> "%L%"
  echo all done %DATE% %TIME% >> "%L%"
  exit /b 0
)
echo ffmpeg -version ok %TIME% >> "%L%"
if not exist "%V%\opus1524b" mkdir "%V%\opus1524b"
set "B=%V%\board1119\OPUS1524E_WAIT_out_before.txt"
dir /b /ad "%V%\opus1524b\out_*" > "%B%" 2>nul
echo OPUS1524_SHOTS4 start %TIME% >> "%L%"
call "%V%\wait1524c\OPUS1524_SHOTS2.bat" > "%V%\opus1524b\shots2_try2_console.txt" 2>&1
echo OPUS1524_SHOTS4 exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1524b >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0