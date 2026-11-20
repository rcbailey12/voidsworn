@echo off
title GPU line: playtest exe for the 1120 council audit, main 3c615257 (Board, Nov 20)
rem Board, Nov 20 16:10 UTC (Ryan R319): waits (60 s steps, up to 160 hours) for 1272 TIMING2's own end line "OPUS1272_TIMING2 exit" in
rem opus1272_timing2_wait.txt, refreshes repo-mirror.git under its lock for 3c615257, then (fail closed, each step only if the one before passed):
rem  1. build\g2_pt_3c61525_1120council.bat from build\ (ship check, sync, packaged ship check, prepare, g2_export, capture into shots\<T>\)
rem  2. a fresh clone of the pin in pt1120council\repo (from the mirror), with build\godot's ships and gen copied in (copy only)
rem  3. player_path.bat from that clone on build\export, both fresh Sunward routes, into shots\<T>\player_path\
rem  4. frontend_ui_check.bat from that clone (its own new shots\frontend_ui\<commit>_<time>\)
rem Then the tools_live janitor --after-job, logged only to janitor_after_pt1120.txt. Every Godot start goes through tmo.bat (main's, identical
rem to tools_live 5b6fdb65e676). Writes pt1120council_wait.txt. Never deletes anything.
setlocal EnableDelayedExpansion
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "T=g2_pt_3c61525_1120council"
set "SHA=3c615257786435138395f99af634e41dc66b8b0b"
set "L=%V%\pt1120council_wait.txt"
set "S=%V%\shots\%T%"
set "OJ_KEEP_CHECKOUTS="
set "PC_GPU_WAIT_SECONDS=3600"
echo waiting for OPUS1272_TIMING2 exit in opus1272_timing2_wait.txt %DATE% %TIME% > "%L%"
set N=0
:wait
findstr /b /c:"OPUS1272_TIMING2 exit" "%V%\opus1272_timing2_wait.txt" >nul 2>&1 && goto go
set /a N+=1
if %N% GEQ 9600 (echo gave up waiting after 160 hours %TIME% >> "%L%" & echo all done >> "%L%" & exit /b 1)
timeout /t 60 /nobreak >nul
goto wait
:go
echo mirror refresh %TIME% >> "%L%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\mirror_refresh_any.ps1" %SHA% >> "%L%" 2>&1
echo PT1120 build start %DATE% %TIME% >> "%L%"
pushd "%V%\build"
call "%V%\build\%T%.bat" > "%V%\pt1120council_build_console.txt" 2>&1
set "BX=!ERRORLEVEL!"
popd
echo PT1120 build exit !BX! at %TIME% >> "%L%"
if not "!BX!"=="0" goto finish
set "R=%V%\pt1120council\repo"
if exist "%R%" (echo FAIL: %R% already exists, not reusing it >> "%L%" & goto finish)
if not exist "%V%\pt1120council" mkdir "%V%\pt1120council"
git -c core.autocrlf=false clone -q --no-checkout "%V%\repo-mirror.git" "%R%" >> "%L%" 2>&1
git -C "%R%" -c core.autocrlf=false checkout -q --detach %SHA% >> "%L%" 2>&1
for /f %%H in ('git -C "%R%" rev-parse HEAD') do echo clone at %%H >> "%L%"
for /f %%H in ('git -C "%R%" rev-parse HEAD') do if not "%%H"=="%SHA%" (echo FAIL: clone is not at the pin >> "%L%" & goto finish)
robocopy "%V%\build\godot\assets\ships" "%R%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NJS /NP > "%V%\pt1120council\log_copy_ships.txt" 2>&1
if !ERRORLEVEL! GEQ 8 (echo FAIL: copy ships >> "%L%" & goto finish)
robocopy "%V%\build\godot\gen" "%R%\godot\gen" /E /NFL /NDL /NJH /NJS /NP > "%V%\pt1120council\log_copy_gen.txt" 2>&1
if !ERRORLEVEL! GEQ 8 (echo FAIL: copy gen >> "%L%" & goto finish)
git -C "%R%" status --porcelain --untracked-files=no > "%V%\pt1120council\tracked_changes.txt" 2>&1
for %%Z in ("%V%\pt1120council\tracked_changes.txt") do if %%~zZ GTR 0 echo note: tracked files changed after the copy, see pt1120council\tracked_changes.txt >> "%L%"
echo PT1120 player_path start %TIME% >> "%L%"
call "%R%\tools\pc\jobs\player_path.bat" "%V%\build\export" "%S%\player_path" > "%S%\player_path_console.txt" 2>&1
echo PT1120 player_path exit !ERRORLEVEL! at %TIME% >> "%L%"
echo PT1120 frontend_ui_check start %TIME% >> "%L%"
dir /b /ad "%V%\shots\frontend_ui" > "%V%\pt1120council\frontend_before.txt" 2>nul
call "%R%\tools\pc\jobs\frontend_ui_check.bat" > "%S%\frontend_ui_console.txt" 2>&1
echo PT1120 frontend_ui_check exit !ERRORLEVEL! at %TIME% >> "%L%"
:finish
set "JTLV=5b6fdb65e676"
if exist "%V%\tools_live\current.txt" set /p JTLV=<"%V%\tools_live\current.txt"
if exist "%V%\tools_live\!JTLV!\pc\janitor.bat" call "%V%\tools_live\!JTLV!\pc\janitor.bat" --after-job >> "%V%\janitor_after_pt1120.txt" 2>&1
echo after-job janitor ran, output in janitor_after_pt1120.txt %TIME% >> "%L%"
echo PT1120 waiter exit at %TIME% >> "%L%"
echo all done %DATE% %TIME% >> "%L%"
exit /b 0