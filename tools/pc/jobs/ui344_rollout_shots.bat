@echo off
rem Issue 344, UI rollout 1 (Lime Tactical on the campaign map and the between-battle pages): parse check and the real game
rem captures of every page at 1920x1080 and 2560x1440 (docs/shots/ui_redesign/rollout1/).
rem Started (not called) by a tiny queue job, in its own window, so the queue stays free.
rem Everything it writes is under Downloads\voidsworn_test\ui_rollout\ : its own clone (repo) and its output (out, or the folder
rem named by the first argument). It reads audit2\repo\godot (gen, ships, the import cache) and copies from it; it deletes nothing.
rem GPU: the watchdog takes a shared claim for each capture (R293); the old nvidia-smi wait is gone (issue 1194).
rem Issue 1194: every step runs through job_wrap.bat from the installed main tools (tools_live), never the old branch
rem checkout being captured. Godot is checked before the clone; a failed clone, fetch, copy or import stops the job, and each
rem parse, check or capture that fails marks it failed while the others still run. It always ends by writing done.txt:
rem PASS or FAILED: <steps>. The exit code is 0 only on PASS. PC_GPU_ISSUE names the GPU claims.
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "U=%VT%\ui_rollout"
set "R=%U%\repo"
set "O=%U%\out"
if not "%~1"=="" set "O=%U%\%~1"
rem Built ships: the shared PC build (build\godot), else the old audit2 checkout; UI_SHIPS overrides (issue 1223).
set "SRC=%UI_SHIPS%"
if "%SRC%"=="" if exist "%VT%\build\godot\gen" set "SRC=%VT%\build\godot"
if "%SRC%"=="" set "SRC=%VT%\audit2\repo\godot"
if not exist "%O%" mkdir "%O%"
echo start %date% %time% > "%O%\status.txt"
if not defined PC_GPU_ISSUE set "PC_GPU_ISSUE=ui344_rollout"
set "JW=%~dp0..\job_wrap.bat"
if exist "%VT%\tools_live\current.txt" for /f "usebackq delims=" %%V in ("%VT%\tools_live\current.txt") do if exist "%VT%\tools_live\%%V\pc\job_wrap.bat" set "JW=%VT%\tools_live\%%V\pc\job_wrap.bat"
call "%JW%" init "%O%" "%PC_GPU_ISSUE%" "godot"
if errorlevel 1 exit /b %ERRORLEVEL%
set "GD=%JW_GODOT%"
rem ---- the clone: fresh, or fetch and check out the branch
if not exist "%R%\.git" (set "JW_STEP=clone" & call "%JW%" run 1800 git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%O%\git.txt" 2>&1)
set "JW_STEP=fetch" & call "%JW%" run 600 git -C "%R%" -c core.autocrlf=false fetch origin opus/issue-344 >> "%O%\git.txt" 2>&1
set "JW_STEP=checkout" & call "%JW%" run 600 git -C "%R%" -c core.autocrlf=false checkout -f -B opus/issue-344 FETCH_HEAD >> "%O%\git.txt" 2>&1
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt" 2>&1
if not exist "%R%\godot\project.godot" (echo CLONE FAILED >> "%O%\status.txt" & call "%JW%" fail "clone" & goto finish)
rem ---- the PC-built folders a fresh clone lacks (copy only)
if not exist "%R%\godot\.godot" call "%JW%" copy "%SRC%\.godot" "%R%\godot\.godot" "%O%\cache_copy.txt"
call "%JW%" copy "%SRC%\assets\ships" "%R%\godot\assets\ships" "%O%\ships_copy.txt" new
call "%JW%" copy "%SRC%\gen" "%R%\godot\gen" "%O%\gen_copy.txt" new
echo clone done %date% %time% >> "%O%\status.txt"
set "JW_STEP=import" & call "%JW%" run 1800 "%GD%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
echo import done %date% %time% >> "%O%\status.txt"
rem ---- parse every script this job changed
if exist "%O%\parse.txt" move /y "%O%\parse.txt" "%O%\parse_previous.txt" > nul
for %%S in (ui/theme/glass_shell.gd campaign/campaign_view.gd ui/campaign/choice_button.gd ui/campaign/map_intel.gd ui/campaign/map3d.gd ui/campaign/campaign_ui.gd scenes/campaign/campaign_scene.gd) do (
  echo == %%S >> "%O%\parse.txt"
  set "JW_STEP=parse %%S" & set "JW_CONTINUE=1" & call "%JW%" run 120 "%GD%" --headless --path "%R%\godot" --check-only --script res://%%S >> "%O%\parse.txt" 2>&1
  echo exit !ERRORLEVEL! >> "%O%\parse.txt"
)
echo parse done %date% %time% >> "%O%\status.txt"
rem ---- the captures: one seeded run played through the campaign's own actions, every page saved by name
rem the project opens maximised (window/size/mode=2), which overrides --resolution: a windowed override in this clone only
(echo [display]& echo window/size/mode=0)> "%R%\godot\override.cfg"
set "JW_STEP=capture 1080" & set "JW_CONTINUE=1" & set "JW_EXPECT=%O%\1080" & call "%JW%" run 1500 "%GD%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 res://scenes/campaign/campaign.tscn -- rollout "%O%\1080" --no-tips --win 1920x1080 > "%O%\log_1080.txt" 2>&1
echo 1080 done %date% %time% >> "%O%\status.txt"
set "JW_STEP=capture 1440" & set "JW_CONTINUE=1" & set "JW_EXPECT=%O%\1440" & call "%JW%" run 1500 "%GD%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution 2560x1440 res://scenes/campaign/campaign.tscn -- rollout "%O%\1440" --no-tips --win 2560x1440 > "%O%\log_1440.txt" 2>&1
echo 1440 done %date% %time% >> "%O%\status.txt"
:finish
rem done PASS or done FAILED: <steps>, then all done, in status.txt and done.txt; the exit code follows.
call "%JW%" end
endlocal & exit /b %ERRORLEVEL%
