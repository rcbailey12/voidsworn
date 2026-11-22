@echo off
title Opus 1077 rerun: clips, side-by-sides and solo GPU timing on the branch head - GPU job
rem Issue 1077 rerun. Parts 1 to 3 lost their GPU steps: Codex 1070 run 3 held the GPU solo and each step gave up after the
rem default 300 s admission wait (exit 126). Start this after 1070 finishes. It waits up to an hour for each GPU claim
rem (PC_GPU_WAIT_SECONDS=3600, the most gpu_slots.js allows). Reuses the clone in opus1077\repo, moves it to the branch head,
rem refuses a revision without the 9be55f23 lights-out fix, runs both headless checks, records the A16 clips (off and
rem strain, c170 and c26), the two side-by-side AVIs, then the frame times solo (R293): three sessions of the prepared
rem timing and the cold case, off and strain. Writes only under opus1077\ (out_rerun and scratch5, fresh folders).
rem Never deletes anything. Logs to out_rerun\result.txt and ends with "all done".
setlocal EnableDelayedExpansion
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1077
set C=%W%\repo
set O=%W%\out_rerun
set S=%W%\scratch5
if not exist "%O%" mkdir "%O%"
if not exist "%S%" mkdir "%S%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
findstr /b /c:"GPU cleared" "%V%\gpu_go.txt" >nul 2>&1 || (echo gpu_go.txt is not GPU cleared: stopped >> "%RES%" & echo all done >> "%RES%" & exit /b 0)
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
git -C "%C%" fetch -q --depth 1 origin opus/issue-1077 >> "%RES%" 2>&1
git -C "%C%" checkout -q FETCH_HEAD >> "%RES%" 2>&1
for /f %%H in ('git -C "%C%" rev-parse HEAD') do set COMMIT=%%H
echo commit=%COMMIT% >> "%RES%"
findstr /c:"never between them and their else (Fable on PR 1171)" "%C%\godot\fx\fx_death.gd" >nul 2>&1 || (echo STOPPED: %COMMIT% does not contain the 9be55f23 fix >> "%RES%" & echo all done >> "%RES%" & exit /b 1)
echo {"commit": "%COMMIT%"} > "%C%\godot\build_info.json"
rem the installed ships and generated hulls, copied again (robocopy /E only adds and updates; exit 0 to 7 is success, 8+ failed)
robocopy "%V%\build\godot\assets\ships" "%C%\godot\assets\ships" /E /NFL /NDL /NJH /NP > "%O%\log_copy_ships.txt" 2>&1
set E=%ERRORLEVEL%
echo copy ships robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (echo STOPPED: copy ships failed >> "%RES%" & echo all done >> "%RES%" & exit /b 1)
if exist "%V%\build\godot\gen" robocopy "%V%\build\godot\gen" "%C%\godot\gen" /E /NFL /NDL /NJH /NP > "%O%\log_copy_gen.txt" 2>&1
set E=%ERRORLEVEL%
echo copy gen robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (echo STOPPED: copy gen failed >> "%RES%" & echo all done >> "%RES%" & exit /b 1)
certutil -hashfile "%C%\godot\assets\ships\C19_51\C19_51.glb" SHA256 >> "%RES%" 2>&1
if not exist "%C%\godot\bench\opus1077" mkdir "%C%\godot\bench\opus1077"
copy /y "%C%\contrib\opus\flagship_death_1077\*.gd" "%C%\godot\bench\opus1077\" > nul
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set TM=%C%\tools\pc\tmo.bat
set PC_GPU_WAIT_SECONDS=3600
set PC_GPU_ISSUE=1077
cd /d "%C%"
"%GD%" --version >> "%RES%" 2>&1
call "%TM%" 3600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
call "%TM%" 1800 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_story_check.gd -- "%C%\godot\assets\ships\C19_51\C19_51.glb" > "%O%\log_death_story.txt" 2>&1
set E=%ERRORLEVEL%
echo death story exit %E% >> "%RES%"
if not "%E%"=="0" (echo STOPPED after death story >> "%RES%" & echo all done >> "%RES%" & exit /b 1)
call "%TM%" 1800 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\C19_51\C19_51.glb" > "%O%\log_death_seam.txt" 2>&1
set E=%ERRORLEVEL%
echo death seam exit %E% >> "%RES%"
if not "%E%"=="0" (echo STOPPED after death seam >> "%RES%" & echo all done >> "%RES%" & exit /b 1)
rem 1. the clips (frames and stills), off and strain at radius 170 and 26
call "%TM%" 5400 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1077/capture.gd -- clips "%S%" 170,26 > "%O%\log_clips.txt" 2>&1
set E=%ERRORLEVEL%
echo clips exit %E% >> "%RES%"
if not "%E%"=="0" (echo STOPPED after clips >> "%RES%" & echo all done >> "%RES%" & exit /b 1)
for %%R in (170 26) do (
  call "%TM%" 1800 "%GD%" --path "%C%\godot" --windowed --resolution 1920x600 --fixed-fps 30 --write-movie "%O%\FLAGSHIP1077_A16_c%%R_side_by_side.avi" --script res://bench/opus1077/compose.gd -- "%S%" %%R %COMMIT% > "%O%\log_compose_c%%R.txt" 2>&1
  echo compose c%%R exit !ERRORLEVEL! >> "%RES%"
)
for %%V in (off strain) do for %%R in (170 26) do (
  if not exist "%O%\stills\%%V_c%%R" mkdir "%O%\stills\%%V_c%%R"
  copy /y "%S%\%%V_c%%R\*_sheet.jpg" "%O%\stills\%%V_c%%R\" > nul
  copy /y "%S%\%%V_c%%R\timeline.json" "%O%\stills\%%V_c%%R\" > nul
)
for %%F in ("%O%\*.avi") do echo %%~nxF bytes %%~zF >> "%RES%"
rem 2. frame times, solo on the GPU (R293): three sessions, each variant and the cold case in its own process
set PC_GPU_MODE=solo
for %%N in (1 2 3) do for %%V in (off strain) do (
  if not exist "%O%\timing\s%%N" mkdir "%O%\timing\s%%N"
  set VS_DEATH_STORY=%%V
  call "%TM%" 1800 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1077/capture.gd -- timing "%O%\timing\s%%N" > "%O%\timing\s%%N\log_timing_%%V.txt" 2>&1
  echo timing s%%N %%V exit !ERRORLEVEL! >> "%RES%"
  call "%TM%" 1800 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1077/capture.gd -- cold "%O%\timing\s%%N" > "%O%\timing\s%%N\log_cold_%%V.txt" 2>&1
  echo cold s%%N %%V exit !ERRORLEVEL! >> "%RES%"
)
set VS_DEATH_STORY=
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0
