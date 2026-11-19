@echo off
title Opus 1077 part 3: clips again on the fixed branch - GPU job
rem Issue 1077 part 3 (Fable blocker on PR 1171: part 1's "off" path had the wrong lights-out bands): waits until both
rem opus1077\out\result.txt and opus1077\out_cold\result.txt end with "all done", moves the clone to the branch head
rem (9be55f23 or later), runs both headless checks, then records the A16 clips off and strain at c170 and c26 and the two
rem side-by-side AVIs again. Part 2 already redoes the timing on the fixed head. Writes only under opus1077\ (scratch3 and
rem out_clips). Never deletes anything. Logs to out_clips\result.txt.
setlocal EnableDelayedExpansion
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1077
set C=%W%\repo
set O=%W%\out_clips
set S=%W%\scratch3
if not exist "%O%" mkdir "%O%"
if not exist "%S%" mkdir "%S%"
set RES=%O%\result.txt
echo waiting for out and out_cold "all done" > "%RES%"
:wait
findstr /c:"all done" "%W%\out\result.txt" >nul 2>&1 || goto sleep
findstr /c:"all done" "%W%\out_cold\result.txt" >nul 2>&1 && goto go
:sleep
timeout /t 60 /nobreak >nul
goto wait
:go
echo start %DATE% %TIME% >> "%RES%"
findstr /b /c:"GPU cleared" "%V%\gpu_go.txt" >nul 2>&1 || (echo gpu_go.txt is not GPU cleared: stopped >> "%RES%" & echo all done >> "%RES%" & exit /b 0)
git -C "%C%" fetch -q --depth 1 origin opus/issue-1077 >> "%RES%" 2>&1
git -C "%C%" checkout -q FETCH_HEAD >> "%RES%" 2>&1
for /f %%H in ('git -C "%C%" rev-parse HEAD') do set COMMIT=%%H
echo commit=%COMMIT% >> "%RES%"
rem Artoo on PR 1171: film only a revision that holds the lights-out fix
rem (the clone is shallow, so the check reads the fix itself: 9be55f23's line in _power_surface)
findstr /c:"never between them and their else (Fable on PR 1171)" "%C%\godot\fx\fx_death.gd" >nul 2>&1 || (echo STOPPED: %COMMIT% does not contain the 9be55f23 fix >> "%RES%" & echo all done >> "%RES%" & exit /b 1)
echo {"commit": "%COMMIT%"} > "%C%\godot\build_info.json"
copy /y "%C%\contrib\opus\flagship_death_1077\*.gd" "%C%\godot\bench\opus1077\" > nul
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set TM=%C%\tools\pc\tmo.bat
cd /d "%C%"
call "%TM%" 1800 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_story_check.gd -- "%C%\godot\assets\ships\C19_51\C19_51.glb" > "%O%\log_death_story.txt" 2>&1
set E=%ERRORLEVEL%
echo death story exit %E% >> "%RES%"
if not "%E%"=="0" (echo STOPPED after death story >> "%RES%" & echo all done >> "%RES%" & exit /b 1)
call "%TM%" 1800 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\C19_51\C19_51.glb" > "%O%\log_death_seam.txt" 2>&1
set E=%ERRORLEVEL%
echo death seam exit %E% >> "%RES%"
if not "%E%"=="0" (echo STOPPED after death seam >> "%RES%" & echo all done >> "%RES%" & exit /b 1)
call "%TM%" 5400 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1077/capture.gd -- clips "%S%" 170,26 > "%O%\log_clips.txt" 2>&1
set E=%ERRORLEVEL%
echo clips exit %E% >> "%RES%"
if not "%E%"=="0" (echo STOPPED after clips >> "%RES%" & echo all done >> "%RES%" & exit /b 1)
for %%R in (170 26) do (
  call "%TM%" 1800 "%GD%" --path "%C%\godot" --windowed --resolution 1920x600 --fixed-fps 30 --write-movie "%O%\FLAGSHIP1077_A16_c%%R_side_by_side.avi" --script res://bench/opus1077/compose.gd -- "%S%" %%R %COMMIT% > "%O%\log_compose_c%%R.txt" 2>&1
  echo compose c%%R exit !ERRORLEVEL! >> "%RES%"
  if not "!ERRORLEVEL!"=="0" set BAD=1
)
for %%V in (off strain) do for %%R in (170 26) do (
  if not exist "%O%\stills\%%V_c%%R" mkdir "%O%\stills\%%V_c%%R"
  copy /y "%S%\%%V_c%%R\*_sheet.jpg" "%O%\stills\%%V_c%%R\" > nul
  copy /y "%S%\%%V_c%%R\timeline.json" "%O%\stills\%%V_c%%R\" > nul
)
for %%F in ("%O%\*.avi") do echo %%~nxF bytes %%~zF >> "%RES%"
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
if defined BAD (echo STOPPED: a composition failed >> "%RES%" & echo all done >> "%RES%" & exit /b 1)
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0
