@echo off
rem Issue 271 build (Glass Shell bold): parse check and the battle HUD captures the board judges (docs/shots/ui_redesign/build/CAPTURES.md).
rem Started (not called) by a queue job, in its own window, so the queue stays free.
rem Clone: Downloads\voidsworn_test\opus271b\repo (branch opus/issue-271-build); the import cache is seeded from opus207's clone.
rem Output: Downloads\voidsworn_test\opus271b\out\ (status.txt says when each step finished; each capture folder has ui_check.txt).
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\opus271b"
set "R=%W%\repo"
set "O=%W%\out"
set /p G=<"%VT%\godot_path.txt"
if not exist "%O%" mkdir "%O%"
echo start %date% %time% > "%O%\status.txt"
if not exist "%R%\.git" git clone --depth 1 -b opus/issue-271-build https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git.txt" 2>&1
git -C "%R%" fetch --depth 1 origin opus/issue-271-build >> "%O%\git.txt" 2>&1
git -C "%R%" reset --hard FETCH_HEAD >> "%O%\git.txt" 2>&1
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt" 2>&1
if not exist "%R%\godot\.godot" if exist "%VT%\opus207\repo\godot\.godot" robocopy "%VT%\opus207\repo\godot\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\cache_copy.txt" 2>&1
rem the PC-built ship assets (not in git, R144) so the captures show the real hulls
if exist "%VT%\opus207\repo\godot\assets\ships" robocopy "%VT%\opus207\repo\godot\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\ships_copy.txt" 2>&1
echo clone done %date% %time% >> "%O%\status.txt"
set "TMO=%R%\tools\pc\tmo.bat"
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
echo import done %date% %time% >> "%O%\status.txt"
if exist "%O%\parse.txt" del "%O%\parse.txt"
for %%S in (ui/theme/glass_shell.gd ui/battle/hud.gd ui/battle/ui_shots.gd scenes/battle/battle.gd render/board.gd rules/battle_api.gd) do (
  echo == %%S >> "%O%\parse.txt"
  call "%TMO%" 120 "%G%" --headless --path "%R%\godot" --check-only --script res://%%S >> "%O%\parse.txt" 2>&1
  echo exit !ERRORLEVEL! >> "%O%\parse.txt"
)
echo parse done %date% %time% >> "%O%\status.txt"
rem A: 1080p, three ships, the Nemesis and Heat 3, the fleets inside gun reach (planned move with odds, a target, the enemy turn)
call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://scenes/battle/battle.tscn -- --ui-shots "%O%\A_1080" --seed 7 --ui-demo --obj ambush > "%O%\A_1080_log.txt" 2>&1
echo A done %date% %time% >> "%O%\status.txt"
rem B: 1080p, twenty ships (the fleet list must show all 20 with no scroll)
call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://scenes/battle/battle.tscn -- --ui-shots "%O%\B_1080_20" --seed 7 --ui-demo --obj ambush --fleet-size 20 > "%O%\B_1080_20_log.txt" 2>&1
echo B done %date% %time% >> "%O%\status.txt"
rem C and D: 4K (the HUD scales by window height: k = 2.0); the window opens at 3840x2160 on a 4K screen
call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 3840x2160 res://scenes/battle/battle.tscn -- --ui-shots "%O%\C_4k" --seed 7 --ui-demo --obj ambush > "%O%\C_4k_log.txt" 2>&1
echo C done %date% %time% >> "%O%\status.txt"
call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 3840x2160 res://scenes/battle/battle.tscn -- --ui-shots "%O%\D_4k_20" --seed 7 --ui-demo --obj ambush --fleet-size 20 > "%O%\D_4k_20_log.txt" 2>&1
echo D done %date% %time% >> "%O%\status.txt"
rem E: the plain default battle at 1080p (no Nemesis, no Heat, fleets apart): the blocks hide cleanly when there is nothing to show
call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://scenes/battle/battle.tscn -- --ui-shots "%O%\E_1080_plain" --seed 7 > "%O%\E_1080_plain_log.txt" 2>&1
echo all done %date% %time% >> "%O%\status.txt"
exit /b 0
