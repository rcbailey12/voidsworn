@echo off
title A17 (Hullbreaker cruiser, the Pack Hunter) through the recipe, stages 1 to 7 (issue 532) - GPU job
rem Issue 532: the second Hullbreaker ship through the repaired ship recipe, the route A16 proved (issue 592, PRs 596 and 606).
rem Uses the existing opus592\repo clone (no new clone, the PC folder stays lean) and checks out branch opus/issue-532-a17.
rem Stages 1 to 7 for corsair_A17 (job folder recipe\corsair_A17), the install into the clone's own godot folder (folder
rem C15s_23, the corsair Cruiser the game draws; what it replaces is copied aside first, nothing is deleted), the
rem in-game shots at camera 170 and 60, the GPU readback, the authored interiors check, and the death seam check when the
rem branch has it (PR 608). Every stage logs to opus532a17out\log_<stage>.txt; result.txt lists each exit code.
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\opus592\repo
set O=%V%\opus532a17out
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git clone -q --depth 1 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin opus/issue-532-a17 >> "%RES%" 2>&1
git -C "%C%" checkout -q FETCH_HEAD >> "%RES%" 2>&1
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set SHIP=corsair_A17
set RECIPE_NOPAUSE=1
set INSTALL_TO=%C%\godot
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
cd /d "%C%"
"%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
for %%S in (1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export) do call :stage %%S
"%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs corsair --sets battle,close --codes C15s_23 > "%O%\log_shots.txt" 2>&1
echo shots exit %ERRORLEVEL% >> "%RES%"
"%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- C15s_23 > "%O%\log_readback_gpu.txt" 2>&1
echo gpu readback exit %ERRORLEVEL% >> "%RES%"
"%GD%" --headless --path "%C%\godot" --script res://fx/test/authored_interiors_check.gd -- "%C%\godot\assets\ships\C15s_23\C15s_23.glb" > "%O%\log_interiors.txt" 2>&1
echo authored interiors exit %ERRORLEVEL% >> "%RES%"
if not exist "%C%\godot\fx\test\death_seam_check.gd" (echo death seam skipped, PR 608 not in this branch >> "%RES%" & goto end)
"%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\C15s_23\C15s_23.glb" > "%O%\log_death_seam.txt" 2>&1
echo death seam exit %ERRORLEVEL% >> "%RES%"
:end
echo done %DATE% %TIME% >> "%RES%"
exit /b 0
:stage
echo %1 start %TIME% >> "%RES%"
call "%C%\tools\recipe\%1.bat" > "%O%\log_%1.txt" 2>&1
echo %1 exit %ERRORLEVEL% at %TIME% >> "%RES%"
exit /b 0
