@echo off
rem Issue 560, second PC run: the branch's latest commit in the existing lean clone (the installed ships and the import
rem are kept), then the turret check and the attach check on the re-exported C15s_23, then (GPU free first) the look
rem bench's turret rows twice, the second run kept. Writes only under opus560\. Never deletes anything.
setlocal EnableDelayedExpansion
set "R=%USERPROFILE%\Downloads\voidsworn_test"
set "D=%R%\opus560"
set /p G=<"%R%\godot_path.txt"
set "P=%D%\repo\godot"
cd /d "%D%"
echo start %date% %time% > "%D%\status_b.txt"
git -C "%D%\repo" fetch origin opus/issue-560 > "%D%\log_fetch_b.txt" 2>&1
git -C "%D%\repo" checkout -f --detach origin/opus/issue-560 >> "%D%\log_fetch_b.txt" 2>&1
for /f %%H in ('git -C "%D%\repo" rev-parse --short^=8 HEAD') do set "SA=%%H"
echo commit !SA! !time! >> "%D%\status_b.txt"
call "%D%\tmo.bat" 1200 "%G%" --headless --path "%P%" --script res://render/test/turret_check.gd -- --out "%D%\turret_check_pc_b.json" > "%D%\log_turret_check_b.txt" 2>&1
echo turret check exit !errorlevel! !time! >> "%D%\status_b.txt"
call "%D%\tmo.bat" 1200 "%G%" --headless --path "%P%" --script res://fx/test/attach_check.gd -- --only C15s_23 --out "%D%\attach_c15_b.json" > "%D%\log_attach_b.txt" 2>&1
echo attach check exit !errorlevel! !time! >> "%D%\status_b.txt"
powershell -NoProfile -ExecutionPolicy Bypass -File "%D%\gpuwait.ps1" -log "%D%\gpu_log_b.txt"
if errorlevel 1 (
  echo gpu busy for 40 minutes, stopped before the bench >> "%D%\status_b.txt"
  exit /b 1
)
echo gpu free !time! >> "%D%\status_b.txt"
for %%N in (1 2) do (
  call "%D%\tmo.bat" 2400 "%G%" --path "%P%" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%D%\bench_b%%N" --part moments --moments res://bench/look_moments_turrets.json --commit !SA! > "%D%\log_bench_b%%N.txt" 2>&1
  echo bench run %%N exit !errorlevel! !time! >> "%D%\status_b.txt"
)
echo done %date% !time! >> "%D%\status_b.txt"
exit /b 0
