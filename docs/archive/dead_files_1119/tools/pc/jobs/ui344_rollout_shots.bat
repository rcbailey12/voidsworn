@echo off
rem Issue 344, UI rollout 1 (Lime Tactical on the campaign map and the between-battle pages): parse check and the real game
rem captures of every page at 1920x1080 and 2560x1440 (docs/shots/ui_redesign/rollout1/).
rem Started (not called) by a tiny queue job, in its own window, so the queue stays free.
rem Everything it writes is under Downloads\voidsworn_test\ui_rollout\ : its own clone (repo) and its output (out, or the folder
rem named by the first argument). It reads audit2\repo\godot (gen, ships, the import cache) and copies from it; it deletes nothing.
rem GPU: one GPU job at a time. It waits until ship round 7 has finished (opus209\out7\done7.txt) and the graphics card is idle,
rem for up to 120 minutes, before Godot starts. It always ends by writing done.txt in its output folder.
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "U=%VT%\ui_rollout"
set "R=%U%\repo"
set "O=%U%\out"
if not "%~1"=="" set "O=%U%\%~1"
set "GD=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "SRC=%VT%\audit2\repo\godot"
if not exist "%O%" mkdir "%O%"
echo start %date% %time% > "%O%\status.txt"
rem ---- the clone: fresh, or fetch and check out the branch
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git.txt" 2>&1
git -C "%R%" -c core.autocrlf=false fetch origin opus/issue-344 >> "%O%\git.txt" 2>&1
git -C "%R%" -c core.autocrlf=false checkout -f -B opus/issue-344 FETCH_HEAD >> "%O%\git.txt" 2>&1
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt" 2>&1
if not exist "%R%\godot\project.godot" (echo CLONE FAILED >> "%O%\status.txt" & goto finish)
rem ---- the PC-built folders a fresh clone lacks (copy only)
if not exist "%R%\godot\.godot" robocopy "%SRC%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\cache_copy.txt" 2>&1
robocopy "%SRC%\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\ships_copy.txt" 2>&1
robocopy "%SRC%\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > "%O%\gen_copy.txt" 2>&1
echo clone done %date% %time% >> "%O%\status.txt"
set "TMO=%R%\tools\pc\tmo.bat"
rem ---- wait for ship round 7 and an idle graphics card (up to 120 minutes)
set /a W=0
:gpuwait
set G=0
for /f %%G in ('nvidia-smi --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits 2^>nul') do set G=%%G
if exist "%VT%\opus209\out7\done7.txt" if !G! LSS 15 goto gpufree
set /a W+=1
if !W! GEQ 120 goto gpufree
timeout /t 60 /nobreak > nul
goto gpuwait
:gpufree
echo gpu free after !W! min (use !G!) %date% %time% >> "%O%\status.txt"
call "%TMO%" 1800 "%GD%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
echo import done %date% %time% >> "%O%\status.txt"
rem ---- parse every script this job changed
if exist "%O%\parse.txt" del "%O%\parse.txt"
for %%S in (ui/theme/glass_shell.gd campaign/campaign_view.gd ui/campaign/choice_button.gd ui/campaign/map_intel.gd ui/campaign/map3d.gd ui/campaign/campaign_ui.gd scenes/campaign/campaign_scene.gd) do (
  echo == %%S >> "%O%\parse.txt"
  call "%TMO%" 120 "%GD%" --headless --path "%R%\godot" --check-only --script res://%%S >> "%O%\parse.txt" 2>&1
  echo exit !ERRORLEVEL! >> "%O%\parse.txt"
)
echo parse done %date% %time% >> "%O%\status.txt"
rem ---- the captures: one seeded run played through the campaign's own actions, every page saved by name
rem the project opens maximised (window/size/mode=2), which overrides --resolution: a windowed override in this clone only
(echo [display]& echo window/size/mode=0)> "%R%\godot\override.cfg"
call "%TMO%" 1500 "%GD%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://scenes/campaign/campaign.tscn -- rollout "%O%\1080" --no-tips --win 1920x1080 > "%O%\log_1080.txt" 2>&1
echo 1080 done %date% %time% >> "%O%\status.txt"
call "%TMO%" 1500 "%GD%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 2560x1440 res://scenes/campaign/campaign.tscn -- rollout "%O%\1440" --no-tips --win 2560x1440 > "%O%\log_1440.txt" 2>&1
echo 1440 done %date% %time% >> "%O%\status.txt"
:finish
echo all done %date% %time% >> "%O%\status.txt"
echo done > "%O%\done.txt"
exit /b 0
