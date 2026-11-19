@echo off
title C13 (Chorus spitter destroyer) through the recipe (issue 1154) - GPU job
rem Issue 1154: the Chorus spitter destroyer chorus_C13 (data.js b_spitter, game folder B20_11) through the ship recipe.
rem Two runs, one file (the Board queues each through queue\q_c1154.bat):
rem   C13_RUN_1154.bat front   stages 1 to 4 (concept in, the AI shape reference, the outline fit, the sheet hull and its audit)
rem   C13_RUN_1154.bat trace   stages 3 and 4 only, on the stage 2 shape reference already on the PC
rem   C13_RUN_1154.bat kit     stage 4 only, on the stage 3 camera and concept already on the PC
rem   C13_RUN_1154.bat paint   stages 1 to 7, the install into this job's own clone, the GPU readback, the authored interiors
rem                            check, the death seam check and the in-game shots at camera 170 and 60. Set PAINT_BASE to a
rem                            branch to merge first (codex/issue-1058 while PR 1083 carries the Chorus paint stack): the
rem                            pictures from such a run are a labelled PREVIEW of that stack, not the final paint.
rem Clones its own folder opus1154\repo (shallow) on branch opus/issue-1154; nothing outside opus1154 and opus1154out is written,
rem nothing is deleted. An install replaces only the clone's own godot\assets\ships\B20_11 (copied aside first by stage 7).
rem Every step logs to opus1154out\<mode>\log_<step>.txt; result.txt lists each exit code. A failed stage skips the later ones.
setlocal
set MODE=%1
if "%MODE%"=="" set MODE=front
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\opus1154\repo
set O=%V%\opus1154out\%MODE%
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %MODE% %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git clone -q --depth 50 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 50 origin opus/issue-1154 >> "%RES%" 2>&1
git -C "%C%" checkout -q -B run1154 FETCH_HEAD >> "%RES%" 2>&1
if not "%PAINT_BASE%"=="" (
  git -C "%C%" fetch -q --depth 50 origin %PAINT_BASE% >> "%RES%" 2>&1
  git -C "%C%" -c user.name=opus1154 -c user.email=opus1154@localhost merge -q --no-edit FETCH_HEAD >> "%RES%" 2>&1
  echo merged %PAINT_BASE% exit %ERRORLEVEL% PREVIEW >> "%RES%"
)
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set RECIPE_NOPAUSE=1
rem Wait up to an hour for a GPU slot (the default 300 s lost two runs to other lanes) and name this job on its claim.
set PC_GPU_WAIT_SECONDS=3600
set PC_GPU_ISSUE=1154
set INSTALL_TO=%C%\godot
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set SHIP=chorus_C13
set CODE=B20_11
set CAMJ=
set FAILED=
cd /d "%C%"
if "%MODE%"=="kit" (
  call :stage 4_parts_kit
  goto end
)
if "%MODE%"=="trace" (
  for %%S in (3_trace_hull 4_parts_kit) do call :stage %%S
  goto end
)
if "%MODE%"=="front" (
  for %%S in (1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit) do call :stage %%S
  goto end
)
call "%~dp0..\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
rem Stages 1 and 2 ran in the front run (the concept and the AI shape reference do not change with the sheet); set FULL=1 to rerun them.
set STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export
if "%FULL%"=="1" set STAGES=1_concept_in 2_shape_ref %STAGES%
rem SKIP3=1 starts at stage 4 when stage 3 already ran on this sheet outline (a hard point or paint change only).
if "%SKIP3%"=="1" set STAGES=4_parts_kit 5_paint_bake 6_lod 7_export
for %%S in (%STAGES%) do call :stage %%S
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
