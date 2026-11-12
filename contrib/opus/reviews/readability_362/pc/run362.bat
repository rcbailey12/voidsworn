@echo off
rem Issue 362 PC run (Opus worker). One job file for every step; the step is the first word:
rem   run362.bat setup              lean sparse clone of opus/issue-362 in opus362\repo, the PC-built hulls copied in
rem                                 (copy only) from audit2\repo\godot, as the look bench does (LB_SHIPS default)
rem   run362.bat probe REF NAME [VARIANTS] [SKIES]   readability probe (fleet at camera 170 plus hull masks), twice
rem                                 (set PX first for more probe options, e.g. --cam 60 --cell 1440x840 --factions deathless)
rem   run362.bat moments REF NAME   the look bench moments part, twice (RULEBOOK 12.5: keep the second run)
rem   run362.bat gate REF NAME      the scene gate (R116): base and res_2160, twice
rem   run362.bat sheets BEFORE AFTER   moments sheets with look_bench_sheets.py (ComfyUI's portable Python)
rem Every GPU step waits until the GPU is under 15 percent twice in a row first. Writes only under opus362\. Never
rem deletes anything. Logs: opus362\status.txt and opus362\log_*.txt.
setlocal EnableDelayedExpansion
set "R=%USERPROFILE%\Downloads\voidsworn_test"
set "D=%R%\opus362"
set /p G=<"%R%\godot_path.txt"
set "P=%D%\repo\godot"
set "S=%D%\status.txt"
set "SRC=%R%\audit2\repo\godot"
cd /d "%D%"
echo %date% %time% start %* >> "%S%"
if /i "%~1"=="setup" goto setup
if /i "%~1"=="probe" goto probe
if /i "%~1"=="moments" goto moments
if /i "%~1"=="gate" goto gate
if /i "%~1"=="sheets" goto sheets
echo unknown step %1 >> "%S%"
exit /b 1

:setup
if not exist "%D%\repo\.git" (
  git -c core.autocrlf=false clone --filter=blob:none --sparse --branch opus/issue-362 https://github.com/rcbailey12/voidsworn.git "%D%\repo" > "%D%\log_clone.txt" 2>&1
  git -C "%D%\repo" sparse-checkout set --no-cone "/godot/*" "!/godot/music/" "!/godot/portraits/" "!/godot/fx/test/results/" "!/godot/assets/ships/previews/" "/tools/pc/jobs/look_bench_sheets.py" "/contrib/opus/reviews/readability_362/*" >> "%D%\log_clone.txt" 2>&1
)
git -C "%D%\repo" fetch origin opus/issue-362 main >> "%D%\log_clone.txt" 2>&1
git -C "%D%\repo" checkout -f --detach origin/opus/issue-362 >> "%D%\log_clone.txt" 2>&1
if not exist "%P%\project.godot" (
  echo clone failed >> "%S%"
  exit /b 1
)
robocopy "%SRC%\gen" "%P%\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%D%\log_copy.txt" 2>&1
robocopy "%SRC%\assets\ships" "%P%\assets\ships" /E /XC /XN /XO /XF manifest.json README.md a4_props.gd /XD test previews /NFL /NDL /NJH /NJS /R:1 /W:1 >> "%D%\log_copy.txt" 2>&1
if not exist "%P%\.godot" robocopy "%SRC%\.godot" "%P%\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 >> "%D%\log_copy.txt" 2>&1
echo %date% %time% setup done >> "%S%"
exit /b 0

rem ---- check out REF, put the probe files in, import (headless, no GPU needed)
:prep
git -C "%D%\repo" fetch origin opus/issue-362 main >> "%D%\log_fetch.txt" 2>&1
if not exist "%D%\tool" mkdir "%D%\tool"
git -C "%D%\repo" checkout -f --detach origin/opus/issue-362 >> "%D%\log_fetch.txt" 2>&1
copy /y "%D%\repo\contrib\opus\reviews\readability_362\pc\readability_probe.gd" "%D%\tool\" > nul
copy /y "%D%\repo\contrib\opus\reviews\readability_362\pc\readability_probe.tscn" "%D%\tool\" > nul
copy /y "%D%\repo\contrib\opus\reviews\readability_362\pc\*.json" "%D%\tool\" > nul
copy /y "%D%\repo\tools\pc\jobs\look_bench_sheets.py" "%D%\tool\" > nul
git -C "%D%\repo" checkout -f --detach %1 >> "%D%\log_fetch.txt" 2>&1
if errorlevel 1 (
  echo cannot check out %1 >> "%S%"
  exit /b 1
)
for /f %%H in ('git -C "%D%\repo" rev-parse --short^=8 HEAD') do set "SHA=%%H"
copy /y "%D%\tool\readability_probe.gd" "%P%\bench\" > nul
copy /y "%D%\tool\readability_probe.tscn" "%P%\bench\" > nul
call "%D%\tmo.bat" 1800 "%G%" --headless --path "%P%" --import > "%D%\log_import_%SHA%.txt" 2>&1
echo %date% %time% prepared %1 %SHA% import exit !errorlevel! >> "%S%"
exit /b 0

:gpu
powershell -NoProfile -ExecutionPolicy Bypass -File "%D%\gpuwait.ps1" -log "%D%\gpu_log.txt"
if errorlevel 1 (
  echo %date% %time% GPU busy for 90 minutes, step stopped >> "%S%"
  exit /b 1
)
echo %date% %time% gpu free >> "%S%"
exit /b 0

:probe
call :prep %2
if errorlevel 1 exit /b 1
set "VARG="
if not "%~4"=="" if /i not "%~4"=="none" set "VARG=--variants %D%\tool\%~4"
set "SKY=world,frontier,storm"
if not "%~5"=="" set "SKY=%~5"
set "REPS=2"
if not "%~4"=="" if /i not "%~4"=="none" set "REPS=1"
call :probe1 %3 1
if "%REPS%"=="2" call :probe1 %3 2
exit /b 0

:probe1
call :gpu
if errorlevel 1 exit /b 1
call "%D%\tmo.bat" 2400 "%G%" --path "%P%" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/readability_probe.tscn -- --out "%D%\probe_%1_%2" --skies %SKY% %VARG% --commit %SHA% %PX% > "%D%\log_probe_%1_%2.txt" 2>&1
echo %date% %time% probe %1 run %2 exit !errorlevel! >> "%S%"
findstr /c:"READ_PROBE_DONE" "%D%\log_probe_%1_%2.txt" > nul
if errorlevel 1 echo probe %1 run %2 DID NOT FINISH >> "%S%"
findstr /c:"placeholder hull" "%D%\log_probe_%1_%2.txt" > nul
if not errorlevel 1 echo probe %1 run %2 PLACEHOLDER HULL, stopped >> "%S%"
exit /b 0

:moments
call :prep %2
if errorlevel 1 exit /b 1
call :moments1 %3 1
call :moments1 %3 2
exit /b 0

:moments1
call :gpu
if errorlevel 1 exit /b 1
call "%D%\tmo.bat" 3600 "%G%" --path "%P%" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%D%\moments_%1_%2" --part moments --commit %SHA% > "%D%\log_moments_%1_%2.txt" 2>&1
echo %date% %time% moments %1 run %2 exit !errorlevel! >> "%S%"
findstr /c:"LOOK_BENCH_DONE" "%D%\log_moments_%1_%2.txt" > nul
if errorlevel 1 echo moments %1 run %2 DID NOT FINISH >> "%S%"
exit /b 0

:gate
call :prep %2
if errorlevel 1 exit /b 1
call :gate1 %3 1
call :gate1 %3 2
exit /b 0

:gate1
call :gpu
if errorlevel 1 exit /b 1
call "%D%\tmo.bat" 1800 "%G%" --path "%P%" --rendering-method forward_plus --windowed --resolution 1920x1080 res://bench/scene_gate.tscn -- --out "%D%\gate_%1_%2" --modes base,res_2160 > "%D%\log_gate_%1_%2.txt" 2>&1
echo %date% %time% gate %1 run %2 exit !errorlevel! >> "%S%"
exit /b 0

:sheets
set "PY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
if not exist "%PY%" (
  echo no ComfyUI python >> "%S%"
  exit /b 1
)
if not exist "%D%\sheets_%~2_vs_%~3" mkdir "%D%\sheets_%~2_vs_%~3"
"%PY%" "%D%\tool\look_bench_sheets.py" --after "%D%\%~3" --before "%D%\%~2" --out "%D%\sheets_%~2_vs_%~3" --label-after %~3 --label-before %~2 > "%D%\sheets_%~2_vs_%~3\sheets_log.txt" 2>&1
echo %date% %time% sheets %2 vs %3 exit !errorlevel! >> "%S%"
exit /b 0
