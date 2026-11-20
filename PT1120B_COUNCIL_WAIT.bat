@echo off
title GPU line: playtest exe for the 1120 council audit, opus/issue-1363 42da627c (Board, Nov 20)
rem Board, Nov 20 17:00 UTC (Ryan R319): rerun of PT1120 with the world_rocks.gd export fix; the GPU line is free, so it starts at once;
rem refreshes repo-mirror.git under its lock for 42da627c, then (fail closed, each step only if the one before passed):
rem  1. build\g2_pt_42da627_1120council.bat from build\ (ship check, sync, packaged ship check, prepare, g2_export, capture into shots\<T>\)
rem  2. a fresh clone of the pin in pt1120b\repo (from the mirror), with build\godot's ships and gen copied in (copy only)
rem  3. player_path.bat from that clone on build\export, both fresh Sunward routes, into shots\<T>\player_path\
rem  4. frontend_ui_check.bat from that clone (its own new shots\frontend_ui\<commit>_<time>\)
rem Then the tools_live janitor --after-job, logged only to janitor_after_pt1120b.txt. Every Godot start goes through tmo.bat (main's, identical
rem to tools_live 5b6fdb65e676). Writes pt1120b_wait.txt. Never deletes anything.
setlocal EnableDelayedExpansion
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "T=g2_pt_42da627_1120council"
set "SHA=42da627c453bf5fcf9d78c7f2ebca9f528c828b8"
set "L=%V%\pt1120b_wait.txt"
echo PT1120B waiter start %DATE% %TIME% > "%L%"
set "S=%V%\shots\%T%"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"

echo mirror refresh %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\mirror_refresh_any.ps1" %SHA% >> "%L%" 2>&1
echo PT1120B build start %DATE% %TIME% >> "%L%"
pushd "%V%\build"
call "%V%\build\%T%.bat" > "%V%\pt1120b_build_console.txt" 2>&1
set "BX=!ERRORLEVEL!"
popd
echo PT1120B build exit !BX! at %TIME% >> "%L%"
if not "!BX!"=="0" goto finish
set "R=%V%\pt1120b\repo"
if exist "%R%" (echo FAIL: %R% already exists, not reusing it >> "%L%" & goto finish)
if not exist "%V%\pt1120b" mkdir "%V%\pt1120b"
git -c core.autocrlf=false clone -q --no-checkout "%V%\repo-mirror.git" "%R%" >> "%L%" 2>&1
git -C "%R%" -c core.autocrlf=false checkout -q --detach %SHA% >> "%L%" 2>&1
for /f %%H in ('git -C "%R%" rev-parse HEAD') do echo clone at %%H >> "%L%"
for /f %%H in ('git -C "%R%" rev-parse HEAD') do if not "%%H"=="%SHA%" (echo FAIL: clone is not at the pin >> "%L%" & goto finish)
robocopy "%V%\build\godot\assets\ships" "%R%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NJS /NP > "%V%\pt1120b\log_copy_ships.txt" 2>&1
if !ERRORLEVEL! GEQ 8 (echo FAIL: copy ships >> "%L%" & goto finish)
robocopy "%V%\build\godot\gen" "%R%\godot\gen" /E /NFL /NDL /NJH /NJS /NP > "%V%\pt1120b\log_copy_gen.txt" 2>&1
if !ERRORLEVEL! GEQ 8 (echo FAIL: copy gen >> "%L%" & goto finish)
git -C "%R%" status --porcelain --untracked-files=no > "%V%\pt1120b\tracked_changes.txt" 2>&1
for %%Z in ("%V%\pt1120b\tracked_changes.txt") do if %%~zZ GTR 0 echo note: tracked files changed after the copy, see pt1120b\tracked_changes.txt >> "%L%"
echo PT1120B player_path start %TIME% >> "%L%"
call "%R%\tools\pc\jobs\player_path.bat" "%V%\build\export" "%S%\player_path" > "%S%\player_path_console.txt" 2>&1
echo PT1120B player_path exit !ERRORLEVEL! at %TIME% >> "%L%"
echo PT1120B frontend_ui_check start %TIME% >> "%L%"
dir /b /ad "%V%\shots\frontend_ui" > "%V%\pt1120b\frontend_before.txt" 2>nul
call "%R%\tools\pc\jobs\frontend_ui_check.bat" > "%S%\frontend_ui_console.txt" 2>&1
echo PT1120B frontend_ui_check exit !ERRORLEVEL! at %TIME% >> "%L%"
:finish
set "JTLV=5b6fdb65e676"
if exist "%V%\tools_live\current.txt" set /p JTLV=<"%V%\tools_live\current.txt"
if exist "%V%\tools_live\!JTLV!\pc\janitor.bat" call "%V%\tools_live\!JTLV!\pc\janitor.bat" --after-job >> "%V%\janitor_after_pt1120b.txt" 2>&1
echo after-job janitor ran, output in janitor_after_pt1120b.txt %TIME% >> "%L%"
echo PT1120B waiter exit at %TIME% >> "%L%"
echo all done %DATE% %TIME% >> "%L%"
exit /b 0