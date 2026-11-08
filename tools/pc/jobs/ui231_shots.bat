@echo off
rem Issue 231 (UI spec): parse check, the MN8 debrief mock and the battle UI check with the AC5 menu focus moment.
rem Started (not called) by the queue job q231_ui.bat, in its own window, so the queue stays free.
rem Clone: Downloads\voidsworn_test\opus231\repo (branch opus/issue-231); the import cache is seeded from opus207's clone.
rem Output: Downloads\voidsworn_test\opus231\out\ (status.txt says when each step finished).
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "W=%VT%\opus231"
set "R=%W%\repo"
set "O=%W%\out"
set /p G=<"%VT%\godot_path.txt"
if not exist "%O%" mkdir "%O%"
echo start %date% %time% > "%O%\status.txt"
if not exist "%R%\.git" git clone --depth 1 -b opus/issue-231 https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git.txt" 2>&1
git -C "%R%" fetch --depth 1 origin opus/issue-231 >> "%O%\git.txt" 2>&1
git -C "%R%" reset --hard FETCH_HEAD >> "%O%\git.txt" 2>&1
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt" 2>&1
if not exist "%R%\godot\.godot" if exist "%VT%\opus207\repo\godot\.godot" robocopy "%VT%\opus207\repo\godot\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\cache_copy.txt" 2>&1
echo clone done %date% %time% >> "%O%\status.txt"
set "TMO=%R%\tools\pc\tmo.bat"
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
echo import done %date% %time% >> "%O%\status.txt"
if exist "%O%\parse.txt" del "%O%\parse.txt"
for %%S in (ui/ui_scale.gd ui/battle/hud.gd ui/battle/ui_shots.gd main/title.gd main/main.gd main/load_screen.gd main/campaign_fallback_ui.gd ui/campaign/campaign_ui.gd ui/campaign/map3d.gd ui/career/career_screen.gd ui/career/rename_dialog.gd campaign/test/debrief_mock_shots.gd) do (
  echo == %%S >> "%O%\parse.txt"
  call "%TMO%" 120 "%G%" --headless --path "%R%\godot" --check-only --script res://%%S >> "%O%\parse.txt" 2>&1
  echo exit !ERRORLEVEL! >> "%O%\parse.txt"
)
echo parse done %date% %time% >> "%O%\status.txt"
call "%TMO%" 300 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --script res://campaign/test/debrief_mock_shots.gd -- "%O%\debrief_1080" > "%O%\debrief_1080_log.txt" 2>&1
call "%TMO%" 300 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 3840x2160 --script res://campaign/test/debrief_mock_shots.gd -- "%O%\debrief_2160" > "%O%\debrief_2160_log.txt" 2>&1
echo debrief done %date% %time% >> "%O%\status.txt"
call "%TMO%" 600 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://scenes/battle/battle.tscn -- --ui-shots "%O%\battle_ui_1080" --seed 7 > "%O%\battle_ui_1080_log.txt" 2>&1
call "%TMO%" 600 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 3840x2160 res://scenes/battle/battle.tscn -- --ui-shots "%O%\battle_ui_2160" --seed 7 > "%O%\battle_ui_2160_log.txt" 2>&1
echo all done %date% %time% >> "%O%\status.txt"
exit /b 0
