@echo off
title PT1120C player_path rerun with PC_GPU_ISSUE=1363 (Board, Nov 20)
rem The first player_path run in PT1120C stopped at admission ("GPU: set PC_GPU_ISSUE or JOB_DIR"): the waiter did not set it. Same promoted
rem build\export (25adec31), same clone pt1120c\repo, fresh recording folder shots\g2_pt_25adec3_1120council\player_path_b. Never deletes.
setlocal
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "S=%V%\shots\g2_pt_25adec3_1120council"
set "L=%V%\pt1120c_pp_wait.txt"
set "PC_GPU_ISSUE=1363"
echo PT1120C player_path rerun start %DATE% %TIME% > "%L%"
call "%V%\pt1120c\repo\tools\pc\jobs\player_path.bat" "%V%\build\export" "%S%\player_path_b" > "%S%\player_path_b_console.txt" 2>&1
echo PT1120C player_path rerun exit %ERRORLEVEL% at %TIME% >> "%L%"
exit /b 0