@echo off
rem Issue 271 step 1: the ember battle screen options, captured on the game's own battle at 1920x1080 (capture only).
rem Started (not called) by a queue job, in its own window, so the queue stays free.
rem Clone: Downloads\voidsworn_test\opus271e\repo (main); the capture scripts come from opus271e\src\_ember271 (the copy of
rem contrib/opus/ui_battle_ember/godot/_ember271 in the repo) and are copied into the clone's godot\_ember271 (never committed).
rem Ship files and godot\gen come from build\godot (LOOP.md Known traps); the import cache is seeded from opus271b's clone.
rem Output: opus271e\out\ or the folder named by the first argument (status.txt says when each step finished).
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\opus271e"
set "R=%W%\repo"
set "O=%W%\out"
if not "%~1"=="" set "O=%W%\%~1"
set /p G=<"%VT%\godot_path.txt"
if not exist "%O%" mkdir "%O%"
echo start %date% %time% > "%O%\status.txt"
if not exist "%R%\.git" git -c core.autocrlf=false clone --depth 1 -b main https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git.txt" 2>&1
git -C "%R%" fetch --depth 1 origin main >> "%O%\git.txt" 2>&1
git -C "%R%" reset --hard FETCH_HEAD >> "%O%\git.txt" 2>&1
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt" 2>&1
if not exist "%R%\godot\.godot" if exist "%VT%\opus271b\repo\godot\.godot" robocopy "%VT%\opus271b\repo\godot\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\cache_copy.txt" 2>&1
if exist "%VT%\build\godot\assets\ships" robocopy "%VT%\build\godot\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\ships_copy.txt" 2>&1
if exist "%VT%\build\godot\gen" robocopy "%VT%\build\godot\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\gen_copy.txt" 2>&1
robocopy "%W%\src\_ember271" "%R%\godot\_ember271" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\src_copy.txt" 2>&1
echo clone done %date% %time% >> "%O%\status.txt"
set "TMO=%R%\tools\pc\tmo.bat"
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
echo import done %date% %time% >> "%O%\status.txt"
if exist "%O%\parse.txt" del "%O%\parse.txt"
for %%S in (_ember271/ember_overlay.gd _ember271/ember_shots.gd) do (
  echo == %%S >> "%O%\parse.txt"
  call "%TMO%" 120 "%G%" --headless --path "%R%\godot" --check-only --script res://%%S >> "%O%\parse.txt" 2>&1
  echo exit !ERRORLEVEL! >> "%O%\parse.txt"
)
echo parse done %date% %time% >> "%O%\status.txt"
rem one GPU job at a time (the PC is shared): wait until the GPU is idle on two checks in a row, at most 40 minutes
set GW=0
set IDLE=0
:gpuwait
set U=100
for /f %%U in ('nvidia-smi --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits 2^>nul') do set U=%%U
if !U! LSS 15 (set /a IDLE+=1) else (set IDLE=0)
if !IDLE! GEQ 2 goto gpufree
set /a GW+=1
if !GW! GEQ 80 goto gpufree
timeout /t 30 /nobreak > nul
goto gpuwait
:gpufree
echo gpu free after !GW! checks %date% %time% >> "%O%\status.txt"
call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script res://_ember271/ember_shots.gd -- --ember-out "%O%" --seed 7 --ui-demo --obj ambush --no-tips > "%O%\run_log.txt" 2>&1
echo run exit !ERRORLEVEL! >> "%O%\status.txt"
echo all done %date% %time% >> "%O%\status.txt"
exit /b 0
