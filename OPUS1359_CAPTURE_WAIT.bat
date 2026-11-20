@echo off
title GPU line: 1359 blocker read capture with real ships, d9ca7ec2 (Board, Nov 20)
rem Board, Nov 20 18:06 UTC: waits (60 s steps) for "OPUS1371 stills exit" in opus1371_wait.txt, refreshes repo-mirror.git for d9ca7ec2 (opus/issue-1359,
rem PR 1367), makes a fresh clone in opus1359\repo, copies build\godot's ships and gen in (copy only), then runs res://world/blocker_read_capture.tscn
rem through build\tools\pc\tmo.bat (throwaway profile) with PC_GPU_ISSUE=1359 and VS_1359_HIDE_SHIPS unset: -- --out opus1359\out --only boneyard
rem --looks cine. End line "OPUS1359 capture exit". Writes opus1359_wait.txt. Never deletes.
setlocal EnableDelayedExpansion
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "SHA=d9ca7ec237882f61cbf36a5e06a8d589525de34e"
set "W=%V%\opus1359"
set "R=%W%\repo"
set "L=%V%\opus1359_wait.txt"
set "PC_GPU_ISSUE=1359"
set "PC_GPU_WAIT_SECONDS=3600"
set "VS_1359_HIDE_SHIPS="
set "VS_1359_PROBE="
set /p G=<"%V%\godot_path.txt"
echo waiting for OPUS1371 stills exit in opus1371_wait.txt %DATE% %TIME% > "%L%"
:wait
findstr /b /c:"OPUS1371 stills exit" "%V%\opus1371_wait.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\board1119\mirror_refresh_any.ps1" %SHA% >> "%L%" 2>&1
if exist "%W%" (echo FAIL: %W% already exists >> "%L%" & echo OPUS1359 capture exit 1 at %TIME% >> "%L%" & exit /b 1)
mkdir "%W%"
git -c core.autocrlf=false clone -q --no-checkout "%V%\repo-mirror.git" "%R%" >> "%L%" 2>&1
git -C "%R%" -c core.autocrlf=false checkout -q --detach %SHA% >> "%L%" 2>&1
for /f %%H in ('git -C "%R%" rev-parse HEAD') do echo clone at %%H >> "%L%"
robocopy "%V%\build\godot\assets\ships" "%R%\godot\assets\ships" /E /XF manifest.json README.md a4_props.gd *.uid /XD test previews /NFL /NDL /NJH /NJS /NP > "%W%\log_copy_ships.txt" 2>&1
robocopy "%V%\build\godot\gen" "%R%\godot\gen" /E /NFL /NDL /NJH /NJS /NP > "%W%\log_copy_gen.txt" 2>&1
git -C "%R%" status --porcelain --untracked-files=no > "%W%\tracked_changes.txt" 2>&1
echo import start %TIME% >> "%L%"
call "%V%\build\tools\pc\tmo.bat" 1800 "%G%" --headless --path "%R%\godot" --import > "%W%\log_import.txt" 2>&1
echo import exit !ERRORLEVEL! at %TIME% >> "%L%"
mkdir "%W%\out"
echo capture start %TIME% >> "%L%"
call "%V%\build\tools\pc\tmo.bat" 1200 "%G%" --path "%R%\godot" --rendering-method forward_plus --resolution 1280x720 res://world/blocker_read_capture.tscn -- --out "%W%\out" --only boneyard --looks cine > "%W%\log_capture.txt" 2>&1
echo OPUS1359 capture exit !ERRORLEVEL! at %TIME% >> "%L%"
exit /b 0