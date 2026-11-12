@echo off
rem Issue 271 step 2: before (main, the Lime HUD) and after (opus/issue-271-build2, E1 LEDGER) pictures of the real battle
rem screen at 1920x1080. Started (not called) by a queue job, in its own window, so the queue stays free.
rem Clones: Downloads\voidsworn_test\opus271b2\main and \branch. The capture script comes from opus271b2\src\_build271 (the
rem copy of contrib/opus/ui_battle_ember/build/_build271) and is copied into each clone's godot\_build271 (never committed).
rem Ship files and godot\gen come from build\godot (LOOP.md Known traps); the import cache is seeded from opus271e's clone.
rem Output: opus271b2\out\ (status.txt says when each step finished). Waits for an idle GPU first. Deletes nothing.
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\opus271b2"
set "O=%W%\out"
if not "%~1"=="" set "O=%W%\%~1"
set /p G=<"%VT%\godot_path.txt"
if not exist "%O%" mkdir "%O%"
echo start %date% %time% > "%O%\status.txt"
call :prep main main
call :prep branch opus/issue-271-build2
echo clones done %date% %time% >> "%O%\status.txt"
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
call "%W%\branch\tools\pc\tmo.bat" 900 "%G%" --path "%W%\main\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script res://_build271/build_shots.gd -- --b271-out "%O%" --b271-tag before --seed 7 --ui-demo --obj ambush --no-tips > "%O%\run_before.txt" 2>&1
echo before exit !ERRORLEVEL! %date% %time% >> "%O%\status.txt"
call "%W%\branch\tools\pc\tmo.bat" 900 "%G%" --path "%W%\branch\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script res://_build271/build_shots.gd -- --b271-out "%O%" --b271-tag after --seed 7 --ui-demo --obj ambush --no-tips > "%O%\run_after.txt" 2>&1
echo after exit !ERRORLEVEL! %date% %time% >> "%O%\status.txt"
echo all done %date% %time% >> "%O%\status.txt"
exit /b 0

:prep
set "R=%W%\%~1"
if not exist "%R%\.git" git -c core.autocrlf=false clone --depth 1 -b %~2 https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git_%~1.txt" 2>&1
git -C "%R%" fetch --depth 1 origin %~2 >> "%O%\git_%~1.txt" 2>&1
git -C "%R%" reset --hard FETCH_HEAD >> "%O%\git_%~1.txt" 2>&1
git -C "%R%" log -1 --format=%%H > "%O%\commit_%~1.txt" 2>&1
if not exist "%R%\godot\.godot" if exist "%VT%\opus271e\repo\godot\.godot" robocopy "%VT%\opus271e\repo\godot\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\cache_%~1.txt" 2>&1
if exist "%VT%\build\godot\assets\ships" robocopy "%VT%\build\godot\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\ships_%~1.txt" 2>&1
if exist "%VT%\build\godot\gen" robocopy "%VT%\build\godot\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\gen_%~1.txt" 2>&1
robocopy "%W%\src\_build271" "%R%\godot\_build271" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\src_%~1.txt" 2>&1
call "%R%\tools\pc\tmo.bat" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\import_%~1.txt" 2>&1
echo prep %~1 done %date% %time% >> "%O%\status.txt"
exit /b 0
