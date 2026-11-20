@echo off
title Code-only: 1186 runner tests, node only, no GPU (Board, Nov 20)
rem Board, Nov 20 15:59 UTC: runs now, outside the ship and GPU lines. Refreshes repo-mirror.git under its lock for e11b41f7, then runs
rem wait1186\OPUS1186_RUN.bat (inbox ba85789, sha256 818013ee; shared opus_job_head, TOOLS=node) and waits for the new opus1186\out_* status.txt
rem to reach "all done". Its own end line is "OPUS1186_RUN exit". OJ_KEEP_CHECKOUTS unset. Writes opus1186_run_wait.txt. Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\opus1186_run_wait.txt"
set "OJ_KEEP_CHECKOUTS="
echo 1186 waiter start %DATE% %TIME% > "%L%"
if not exist "%V%\opus1186" mkdir "%V%\opus1186"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\mirror_refresh_any.ps1" e11b41f7fba62ab9a22e873033b1a65e153b828b >> "%L%" 2>&1
set "B=%V%\board1119\run1186_out_before.txt"
dir /b /ad "%V%\opus1186\out_*" > "%B%" 2>nul
echo OPUS1186_RUN start %TIME% >> "%L%"
call "%V%\wait1186\OPUS1186_RUN.bat" > "%V%\opus1186\run_console.txt" 2>&1
echo OPUS1186_RUN exit %ERRORLEVEL% at %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\wait_new_out_any.ps1" "%B%" "%L%" opus1186 >> "%L%" 2>&1
echo all done %DATE% %TIME% >> "%L%"
exit /b 0