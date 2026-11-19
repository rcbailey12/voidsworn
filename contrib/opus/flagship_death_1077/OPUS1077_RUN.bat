@echo off
title Opus 1077: flagship death prototype clips and solo GPU timing - GPU job
rem Issue 1077 (Opus worker thread "Prototype the flagship death"): A16 (C19_51) dying on today's path and with the strain
rem prototype (rendering/effects/death_story, off by default), at the battle camera and close; then frame times solo on
rem the GPU (R293) for the first death in a process and one, two and three A16 dying at once, off and strain, three
rem sessions each, plus a cold case per session (fresh process, no warm-up, no prepared cut: Artoo on PR 1171). Fresh clone of branch opus/issue-1077 in opus1077\repo; the installed ships are COPIED into the clone
rem (the shared build is only read). Writes only under opus1077\. Never deletes anything. Every step logs to out\result.txt.
setlocal EnableDelayedExpansion
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1077
set C=%W%\repo
set O=%W%\out
set S=%W%\scratch
if not exist "%W%" mkdir "%W%"
if not exist "%O%" mkdir "%O%"
if not exist "%S%" mkdir "%S%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
findstr /b /c:"GPU cleared" "%V%\gpu_go.txt" >nul 2>&1 || (echo gpu_go.txt is not GPU cleared: stopped >> "%RES%" & echo all done >> "%RES%" & exit /b 0)
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
if not exist "%C%\.git" git -c core.autocrlf=false clone -q --depth 1 --branch opus/issue-1077 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin opus/issue-1077 >> "%RES%" 2>&1
git -C "%C%" checkout -q FETCH_HEAD >> "%RES%" 2>&1
for /f %%H in ('git -C "%C%" rev-parse HEAD') do set COMMIT=%%H
echo commit=%COMMIT% >> "%RES%"
echo {"commit": "%COMMIT%"} > "%C%\godot\build_info.json"
rem the installed ships and generated hulls, copied (robocopy /E only adds and updates; it removes nothing)
robocopy "%V%\build\godot\assets\ships" "%C%\godot\assets\ships" /E /NFL /NDL /NJH /NP > "%O%\log_copy_ships.txt" 2>&1
echo copy ships exit %ERRORLEVEL% >> "%RES%"
if exist "%V%\build\godot\gen" robocopy "%V%\build\godot\gen" "%C%\godot\gen" /E /NFL /NDL /NJH /NP > "%O%\log_copy_gen.txt" 2>&1
echo copy gen exit %ERRORLEVEL% >> "%RES%"
certutil -hashfile "%C%\godot\assets\ships\manifest.json" SHA256 >> "%RES%" 2>&1
certutil -hashfile "%C%\godot\assets\ships\C19_51\C19_51.glb" SHA256 >> "%RES%" 2>&1
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set TM=%C%\tools\pc\tmo.bat
cd /d "%C%"
rem the adapters run inside the clone's project (they extend the shipped look bench)
if not exist "%C%\godot\bench\opus1077" mkdir "%C%\godot\bench\opus1077"
copy /y "%C%\contrib\opus\flagship_death_1077\*.gd" "%C%\godot\bench\opus1077\" > nul
call "%TM%" 3600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
rem the headless checks on the installed A16: today's seams and the prototype's grouping
call "%TM%" 1800 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\C19_51\C19_51.glb" > "%O%\log_death_seam.txt" 2>&1
echo death seam exit %ERRORLEVEL% >> "%RES%"
call "%TM%" 1800 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_story_check.gd -- "%C%\godot\assets\ships\C19_51\C19_51.glb" > "%O%\log_death_story.txt" 2>&1
echo death story exit %ERRORLEVEL% >> "%RES%"
rem 1. the clips (frames and stills), off and strain at radius 170 and 26
call "%TM%" 5400 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1077/capture.gd -- clips "%S%" 170,26 > "%O%\log_clips.txt" 2>&1
echo clips exit %ERRORLEVEL% >> "%RES%"
for %%R in (170 26) do (
  call "%TM%" 1800 "%GD%" --path "%C%\godot" --windowed --resolution 1920x600 --fixed-fps 30 --write-movie "%O%\FLAGSHIP1077_A16_c%%R_side_by_side.avi" --script res://bench/opus1077/compose.gd -- "%S%" %%R %COMMIT% > "%O%\log_compose_c%%R.txt" 2>&1
  echo compose c%%R exit !ERRORLEVEL! >> "%RES%"
)
for %%V in (off strain) do for %%R in (170 26) do (
  if not exist "%O%\stills\%%V_c%%R" mkdir "%O%\stills\%%V_c%%R"
  copy /y "%S%\%%V_c%%R\*_sheet.jpg" "%O%\stills\%%V_c%%R\" > nul
  copy /y "%S%\%%V_c%%R\timeline.json" "%O%\stills\%%V_c%%R\" > nul
)
rem 2. frame times, solo on the GPU (R293): three sessions of each variant, each in its own process
set PC_GPU_MODE=solo
set PC_GPU_ISSUE=1077
for %%N in (1 2 3) do for %%V in (off strain) do (
  if not exist "%O%\timing\s%%N" mkdir "%O%\timing\s%%N"
  set VS_DEATH_STORY=%%V
  call "%TM%" 1800 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1077/capture.gd -- timing "%O%\timing\s%%N" > "%O%\timing\s%%N\log_%%V.txt" 2>&1
  echo timing s%%N %%V exit !ERRORLEVEL! >> "%RES%"
  call "%TM%" 1800 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1077/capture.gd -- cold "%O%\timing\s%%N" > "%O%\timing\s%%N\log_cold_%%V.txt" 2>&1
  echo cold s%%N %%V exit !ERRORLEVEL! >> "%RES%"
)
set VS_DEATH_STORY=
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0
