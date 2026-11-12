@echo off
rem Issue 560, one PC run. Writes only under opus560\. Never deletes anything.
rem Part A (no GPU): a lean sparse clone of opus/issue-560; the stage 7 export of the round 8b baked cruiser
rem (opus209\out8b\Ab8.blend, opened read only and never saved) with its two turrets as their own nodes; the export check
rem and its selftest; the new export installed in the clone with the two hulls the bench needs (V14_23, D21_23);
rem the game's import and asset build; the turret check and the attach check on the installed ship.
rem Part B (GPU, after the GPU is free): the look bench's turret rows (godot\bench\look_moments_turrets.json), twice; the
rem second run is kept (RULEBOOK 12.5).
setlocal EnableDelayedExpansion
set "R=%USERPROFILE%\Downloads\voidsworn_test"
set "D=%R%\opus560"
set /p G=<"%R%\godot_path.txt"
set "B=%R%\blender\blender-4.5.14-windows-x64\blender.exe"
set "BPY=%R%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe"
set "P=%D%\repo\godot"
set "RC=%D%\repo\tools\recipe"
set "EX=%D%\export\C15s_23"
cd /d "%D%"
echo start %date% %time% > "%D%\status.txt"
if not exist "%D%\repo\.git" (
  git -c core.autocrlf=false clone --filter=blob:none --sparse --branch opus/issue-560 https://github.com/rcbailey12/voidsworn.git "%D%\repo" > "%D%\log_clone.txt" 2>&1
  git -C "%D%\repo" sparse-checkout set --no-cone "/godot/*" "/tools/recipe/*" "/tools/blender/kits/*" "/tools/blender/hs/*" "/data.js" "!/godot/music/" "!/godot/portraits/" "!/godot/fx/test/results/" "!/godot/assets/ships/previews/" >> "%D%\log_clone.txt" 2>&1
)
git -C "%D%\repo" fetch origin opus/issue-560 >> "%D%\log_clone.txt" 2>&1
git -C "%D%\repo" checkout -f --detach origin/opus/issue-560 >> "%D%\log_clone.txt" 2>&1
git -C "%D%\repo" rev-parse HEAD > "%D%\commit.txt"
for /f %%H in ('git -C "%D%\repo" rev-parse --short^=8 HEAD') do set "SA=%%H"
if not exist "%P%\project.godot" (
  echo clone failed >> "%D%\status.txt"
  exit /b 1
)
echo clone %SA% %time% >> "%D%\status.txt"
if not exist "%EX%" mkdir "%EX%"
call "%D%\tmo.bat" 1800 "%B%" -b "%R%\opus209\out8b\Ab8.blend" -P "%RC%\export7.py" -- "%RC%\ships\C15s_23.json" "%EX%" maps=2048 > "%D%\log_export.txt" 2>&1
echo export exit !errorlevel! %time% >> "%D%\status.txt"
"%BPY%" "%RC%\check_export.py" "%RC%\ships\C15s_23.json" "%EX%" > "%D%\log_check.txt" 2>&1
set CHK=!errorlevel!
echo check exit !CHK! %time% >> "%D%\status.txt"
"%BPY%" "%RC%\check_export_selftest.py" "%RC%\ships\C15s_23.json" "%EX%" > "%D%\log_selftest.txt" 2>&1
echo selftest exit !errorlevel! %time% >> "%D%\status.txt"
if not "!CHK!"=="0" (
  echo stopped: the export check failed >> "%D%\status.txt"
  exit /b 1
)
robocopy "%R%\build\godot\gen" "%P%\gen" /E /XD hi damage wreck ships /NFL /NDL /NJH /NJS /NP /R:1 /W:1 > "%D%\log_copy.txt" 2>&1
for %%C in (V14_23 D21_23) do robocopy "%R%\build\godot\assets\ships\%%C" "%P%\assets\ships\%%C" /E /XF *.uid /NFL /NDL /NJH /NJS /NP /R:1 /W:1 >> "%D%\log_copy.txt" 2>&1
if not exist "%P%\assets\ships\C15s_23" mkdir "%P%\assets\ships\C15s_23"
copy /y "%EX%\C15s_23.glb" "%P%\assets\ships\C15s_23\" >> "%D%\log_copy.txt" 2>&1
copy /y "%EX%\C15s_23_*.jpg" "%P%\assets\ships\C15s_23\" >> "%D%\log_copy.txt" 2>&1
echo copied %time% >> "%D%\status.txt"
call "%D%\tmo.bat" 3600 "%G%" --headless --path "%P%" --import > "%D%\log_import.txt" 2>&1
echo import exit !errorlevel! %time% >> "%D%\status.txt"
call "%D%\tmo.bat" 2400 "%G%" --headless --path "%P%" --script res://render/build_assets.gd -- --repo "%D%\norepo" > "%D%\log_build.txt" 2>&1
echo build_assets exit !errorlevel! %time% >> "%D%\status.txt"
call "%D%\tmo.bat" 1200 "%G%" --headless --path "%P%" --script res://render/test/turret_check.gd -- --out "%D%\turret_check_pc.json" > "%D%\log_turret_check.txt" 2>&1
echo turret check exit !errorlevel! %time% >> "%D%\status.txt"
call "%D%\tmo.bat" 1200 "%G%" --headless --path "%P%" --script res://fx/test/attach_check.gd -- --only C15s_23 --out "%D%\attach_c15.json" > "%D%\log_attach.txt" 2>&1
echo attach check exit !errorlevel! %time% >> "%D%\status.txt"
powershell -NoProfile -ExecutionPolicy Bypass -File "%D%\gpuwait.ps1" -log "%D%\gpu_log.txt"
if errorlevel 1 (
  echo gpu busy for 40 minutes, stopped before the bench >> "%D%\status.txt"
  exit /b 1
)
echo gpu free %time% >> "%D%\status.txt"
for %%N in (1 2) do (
  call "%D%\tmo.bat" 2400 "%G%" --path "%P%" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 res://bench/look_bench.tscn -- --out "%D%\bench_%%N" --part moments --moments res://bench/look_moments_turrets.json --commit %SA% > "%D%\log_bench_%%N.txt" 2>&1
  echo bench run %%N exit !errorlevel! %time% >> "%D%\status.txt"
)
echo done %date% %time% >> "%D%\status.txt"
exit /b 0
