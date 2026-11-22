@echo off
setlocal EnableDelayedExpansion
title Ship line CT: 1373N Glasswright GV2, GW4 on board/pin-1373n, then PROBE19B if both pass (Board, Nov 22) - GPU jobs
rem Board, Nov 22 02:30 UTC (Ryan "Good to go"; inbox 979a749d, folder 1373n): refreshes repo-mirror.git (pin-1373n 746d8d7c), runs wait1373n\OPUS1373N_ithar_GV2 (17d41b59, opus1373gv2n) then OPUS1373N_ithar_GW4 (07107524, opus1373gw4n) unedited, trial only, no publish, continuing past a failure.
rem Then, only if both exited 0, calls wait1373n\OPUS1373N_PROBE19B.bat (2a958492, with probe1373n_prep.ps1 0cd97dda beside it) the way chain CS ran PROBE18B; it writes its own end line "1373N PROBE19 exit" into this log. If either failed, writes "1373N PROBE19 exit 8 (not run: ...)".
rem End lines "1373N GV2 exit", "1373N GW4 exit", "1373N PROBE19 exit". Writes chain_1119ct.txt. Never deletes.
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "L=%V%\chain_1119ct.txt"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
echo chain CT start %DATE% %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\mirror_refresh_any.ps1" 746d8d7c9a27a155575727e9e4c018b7ba6ebd66 >> "%L%" 2>&1
echo 1373N GV2 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "PUBLISH=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "SHIP=" & set "CODE=" & set "BRANCH=" & set "JOB_DIR=" & set "FACS=" & set "PC_GPU_ISSUE=1373" & call "%V%\wait1373n\OPUS1373N_ithar_GV2.bat" & endlocal
set "E1=!ERRORLEVEL!"
echo 1373N GV2 exit !E1! at %TIME% >> "%L%"
echo 1373N GW4 start %TIME% >> "%L%"
setlocal & set "PIN=" & set "PUBLISH=" & set "STAGES=" & set "PAINT_BASE=" & set "SETS=" & set "SHIP=" & set "CODE=" & set "BRANCH=" & set "JOB_DIR=" & set "FACS=" & set "PC_GPU_ISSUE=1373" & call "%V%\wait1373n\OPUS1373N_ithar_GW4.bat" & endlocal
set "E2=!ERRORLEVEL!"
echo 1373N GW4 exit !E2! at %TIME% >> "%L%"
if not "!E1!"=="0" (echo 1373N PROBE19 exit 8 at %TIME% ^(not run: GV2 exit !E1!^) >> "%L%" & goto tail)
if not "!E2!"=="0" (echo 1373N PROBE19 exit 8 at %TIME% ^(not run: GW4 exit !E2!^) >> "%L%" & goto tail)
echo 1373N PROBE19B start %TIME% >> "%L%"
call "%V%\wait1373n\OPUS1373N_PROBE19B.bat"
findstr /b /c:"1373N PROBE19 exit" "%L%" >nul 2>&1 || echo 1373N PROBE19 exit 9 at %TIME%, the bat ended without its own end line >> "%L%"
:tail
set "JTLV=a41a4147845e"
if exist "%V%\tools_live\current.txt" set /p JTLV=<"%V%\tools_live\current.txt"
if exist "%V%\tools_live\!JTLV!\pc\janitor.bat" call "%V%\tools_live\!JTLV!\pc\janitor.bat" --after-job >> "%V%\janitor_after_1119ct.txt" 2>&1
echo after-job janitor ran %TIME% >> "%L%"
echo all done %DATE% %TIME% >> "%L%"
exit /b 0