@echo off
title C14 (Chorus brood-sac carrier) through the recipe (issue 1155) - GPU job
rem Issue 1155: the Chorus brood-sac carrier chorus_C14 (data.js b_brood, game folder B22_11) through the ship recipe.
rem Two runs, one file (the Board queues each through queue\q_c1155.bat):
rem   C14_RUN_1155.bat front   stages 1 to 4 (concept in, the AI shape reference, the outline fit, the sheet hull and its audit)
rem   C14_RUN_1155.bat paint   stages 1 to 7, the install into this job's own clone, the GPU readback, the authored interiors
rem                            check, the death seam check and the in-game shots at camera 170 and 60. Set PAINT_BASE to a
rem                            branch to merge first (codex/issue-1058 while PR 1083 carries the Chorus paint stack): the
rem                            pictures from such a run are a labelled PREVIEW of that stack, not the final paint.
rem Clones its own folder opus1155\repo (shallow) on branch opus/issue-1155; nothing outside opus1155 and opus1155out is written,
rem nothing is deleted. An install replaces only the clone's own godot\assets\ships\B22_11 (copied aside first by stage 7).
rem Every step logs to opus1155out\<mode>\log_<step>.txt; result.txt lists each exit code. A failed stage skips the later ones.
setlocal
set MODE=%1
if "%MODE%"=="" set MODE=front
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\opus1155\repo
set O=%V%\opus1155out\%MODE%
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %MODE% %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git clone -q --depth 50 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 50 origin opus/issue-1155 >> "%RES%" 2>&1
git -C "%C%" checkout -q -B run1155 FETCH_HEAD >> "%RES%" 2>&1
if not "%PAINT_BASE%"=="" (
  git -C "%C%" fetch -q --depth 50 origin %PAINT_BASE% >> "%RES%" 2>&1
  git -C "%C%" -c user.name=opus1155 -c user.email=opus1155@localhost merge -q --no-edit FETCH_HEAD >> "%RES%" 2>&1
  echo merged %PAINT_BASE% exit %ERRORLEVEL% PREVIEW >> "%RES%"
)
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set RECIPE_NOPAUSE=1
set INSTALL_TO=%C%\godot
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set SHIP=chorus_C14
set CODE=B22_11
set CAMJ=
set FAILED=
cd /d "%C%"
if "%MODE%"=="front" (
  for %%S in (1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit) do call :stage %%S
  goto end
)
call "%~dp0..\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
for %%S in (1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export) do call :stage %%S
if defined FAILED (
  echo checks SKIPPED: stage %FAILED% failed, so the installed glb is not this run's >> "%RES%"
  goto end
)
call "%~dp0..\tmo.bat" 21600 "%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- %CODE% > "%O%\log_readback_gpu.txt" 2>&1
echo gpu readback exit %ERRORLEVEL% >> "%RES%"
call "%~dp0..\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --script res://fx/test/authored_interiors_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_interiors.txt" 2>&1
echo authored interiors exit %ERRORLEVEL% >> "%RES%"
call "%~dp0..\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_death_seam.txt" 2>&1
echo death seam exit %ERRORLEVEL% >> "%RES%"
call "%~dp0..\tmo.bat" 21600 "%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs chorus --sets battle,close --codes %CODE% > "%O%\log_shots.txt" 2>&1
echo shots exit %ERRORLEVEL% >> "%RES%"
:end
echo done %DATE% %TIME% >> "%RES%"
exit /b 0

:stage
if defined FAILED (
  echo %1 SKIPPED: stage %FAILED% failed >> "%RES%"
  exit /b 0
)
echo %1 start %TIME% >> "%RES%"
call "%C%\tools\recipe\%1.bat" > "%O%\log_%1.txt" 2>&1
set EL=%ERRORLEVEL%
echo %1 exit %EL% at %TIME% >> "%RES%"
if not "%EL%"=="0" set FAILED=%1
exit /b 0
