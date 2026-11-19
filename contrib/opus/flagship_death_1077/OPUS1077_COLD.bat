@echo off
title Opus 1077 part 2: cold death spike and prepared timing again, solo GPU - GPU job
rem Issue 1077 part 2 (Artoo on PR 1171): waits until opus1077\out\result.txt ends with "all done" (it shares the clone),
rem moves the clone to the branch head (b78e93f0 or later), then, solo on the GPU (R293), three sessions of: the prepared
rem timing again (now with its preparation frames and the "prepared" flag) and the cold case (fresh process, no warm-up,
rem no prepared cut), off and strain. Writes only under opus1077\. Never deletes anything. Logs to out_cold\result.txt.
setlocal EnableDelayedExpansion
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1077
set C=%W%\repo
set O=%W%\out_cold
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo waiting for %W%\out\result.txt "all done" > "%RES%"
:wait
findstr /c:"all done" "%W%\out\result.txt" >nul 2>&1 && goto go
timeout /t 60 /nobreak >nul
goto wait
:go
echo start %DATE% %TIME% >> "%RES%"
findstr /b /c:"GPU cleared" "%V%\gpu_go.txt" >nul 2>&1 || (echo gpu_go.txt is not GPU cleared: stopped >> "%RES%" & echo all done >> "%RES%" & exit /b 0)
git -C "%C%" fetch -q --depth 1 origin opus/issue-1077 >> "%RES%" 2>&1
git -C "%C%" checkout -q FETCH_HEAD >> "%RES%" 2>&1
for /f %%H in ('git -C "%C%" rev-parse HEAD') do set COMMIT=%%H
echo commit=%COMMIT% >> "%RES%"
echo {"commit": "%COMMIT%"} > "%C%\godot\build_info.json"
copy /y "%C%\contrib\opus\flagship_death_1077\*.gd" "%C%\godot\bench\opus1077\" > nul
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set TM=%C%\tools\pc\tmo.bat
cd /d "%C%"
set PC_GPU_MODE=solo
set PC_GPU_ISSUE=1077
for %%N in (1 2 3) do for %%V in (off strain) do (
  if not exist "%O%\s%%N" mkdir "%O%\s%%N"
  set VS_DEATH_STORY=%%V
  call "%TM%" 1800 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1077/capture.gd -- timing "%O%\s%%N" > "%O%\s%%N\log_timing_%%V.txt" 2>&1
  echo timing s%%N %%V exit !ERRORLEVEL! >> "%RES%"
  call "%TM%" 1800 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1077/capture.gd -- cold "%O%\s%%N" > "%O%\s%%N\log_cold_%%V.txt" 2>&1
  echo cold s%%N %%V exit !ERRORLEVEL! >> "%RES%"
)
set VS_DEATH_STORY=
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0
