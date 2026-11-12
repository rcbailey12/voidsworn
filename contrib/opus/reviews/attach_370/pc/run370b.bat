@echo off
rem Issue 370 job B (GPU): the look bench's attach rows (godot\bench\look_moments_attach.json) on main (before) and on
rem opus/issue-370 (after), each benched twice; the second run of each is kept (RULEBOOK 12.5). Both commits run the same
rem bench script and rows, taken from the branch (as look_bench.bat does with LB_TOOL_REF). Writes only under opus370\.
setlocal EnableDelayedExpansion
set "R=%USERPROFILE%\Downloads\voidsworn_test"
set "D=%R%\opus370"
set /p G=<"%R%\godot_path.txt"
set "P=%D%\repo\godot"
set "T=%D%\bench_tool"
cd /d "%D%"
echo start %date% %time% > "%D%\status_b.txt"
git -C "%D%\repo" fetch origin opus/issue-370 main > "%D%\log_fetch_b.txt" 2>&1
git -C "%D%\repo" checkout -f --detach origin/opus/issue-370 >> "%D%\log_fetch_b.txt" 2>&1
if not exist "%T%" mkdir "%T%"
copy /y "%P%\bench\look_bench.gd" "%T%\" > nul
copy /y "%P%\bench\look_bench.tscn" "%T%\" > nul
copy /y "%P%\bench\look_moments_attach.json" "%T%\" > nul
for /f %%H in ('git -C "%D%\repo" rev-parse --short^=8 origin/main') do set "SB=%%H"
for /f %%H in ('git -C "%D%\repo" rev-parse --short^=8 origin/opus/issue-370') do set "SA=%%H"
echo before %SB% after %SA% >> "%D%\status_b.txt"
powershell -NoProfile -ExecutionPolicy Bypass -File "%D%\gpuwait.ps1" -log "%D%\gpu_log.txt"
if errorlevel 1 (
  echo gpu busy for 40 minutes, stopped >> "%D%\status_b.txt"
  exit /b 1
)
echo gpu free %time% >> "%D%\status_b.txt"
call :bench origin/main %SB% before
call :bench origin/opus/issue-370 %SA% after
git -C "%D%\repo" checkout -f --detach origin/opus/issue-370 > nul 2>&1
echo done %date% %time% >> "%D%\status_b.txt"
exit /b 0

:bench
git -C "%D%\repo" checkout -f --detach %1 >> "%D%\log_fetch_b.txt" 2>&1
copy /y "%T%\look_bench.gd" "%P%\bench\look_bench.gd" > nul
copy /y "%T%\look_bench.tscn" "%P%\bench\look_bench.tscn" > nul
copy /y "%T%\look_moments_attach.json" "%P%\bench\look_moments_attach.json" > nul
for %%N in (1 2) do (
  call "%D%\tmo.bat" 2400 "%G%" --path "%P%" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%D%\bench_%3_%%N" --part moments --moments res://bench/look_moments_attach.json --commit %2 > "%D%\log_bench_%3_%%N.txt" 2>&1
  echo bench %3 run %%N exit !errorlevel! %time% >> "%D%\status_b.txt"
)
exit /b 0
