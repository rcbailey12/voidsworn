@echo off
title C12 drone-spawn (chorus_C12) through the recipe, stages 1 to 7 (issue 1153) - GPU job
rem Issue 1153: the Chorus drone-spawn frigate (data key b_drone, game folder B19_11, chorus|Frigate in godot/render/hull_table.gd
rem AI_HULLS) from its build sheet chorus_C12, painted with the Chorus kit's paint stack (bake stack; a labelled preview until
rem PR 1083's stack is on main). Adapted from tools/pc/jobs/S10_RUN_1157.bat (R334). Clones its own folder opus1153\repo7 (shallow;
rem a new folder, so it can never meet the older opus1153\repo run) and checks out branch opus/issue-1153. Stages 1 to 7 (job folder
rem recipe\chorus_C12); a failed stage skips the later stages, the checks and the shots. The install goes into the clone's own godot
rem folder only (what it replaces is copied aside first, nothing is deleted, nothing goes into Ryan's own game folder), then the GPU
rem readback, the authored interiors check and the death seam check on the installed glb, then the in-game shots at the battle
rem and close cameras. GPU steps go through tmo.bat, which waits for gpu_go.txt. Run from a copy outside the clone
rem (OPUS1153_RUN.bat copies it to opus1153\). Every step logs to opus1153\out\log_<ship>_<step>.txt; result.txt lists each exit
rem code and ends "all done".
if "%1"=="ship" goto ship
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\opus1153\repo7
set O=%V%\opus1153\out
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git clone -q --depth 1 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin opus/issue-1153 >> "%RES%" 2>&1
git -C "%C%" checkout -q FETCH_HEAD >> "%RES%" 2>&1
if errorlevel 1 (
  echo done FAILED: could not check out opus/issue-1153 %DATE% %TIME% >> "%RES%"
  echo all done >> "%RES%"
  exit /b 1
)
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set RECIPE_NOPAUSE=1
set INSTALL_TO=%C%\godot
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
cd /d "%C%"
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
rem each ship in a fresh cmd: the variables its stages set end with it
cmd /c ""%~f0" ship chorus_C12 B19_11"
set SHIPEL=%ERRORLEVEL%
echo chorus_C12 ship exit %SHIPEL% >> "%RES%"
if "%SHIPEL%"=="0" set SHIPOK=1
rem the in-game shots only after this run's export, install and checks all passed: the clone can still hold an older B19_11
if not "%SHIPEL%"=="0" (
  echo shots SKIPPED: the ship's stages or checks failed, so the installed B19_11 is not this run's >> "%RES%"
  set SHIPFAIL=1
  call :collect
  exit /b 1
)
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs chorus --sets battle,close --codes B19_11 > "%O%\log_shots.txt" 2>&1
set SHOTEL=%ERRORLEVEL%
echo shots exit %SHOTEL% >> "%RES%"
if not "%SHOTEL%"=="0" (
  set SHIPFAIL=1
  call :collect
  exit /b 1
)
call :collect
if errorlevel 1 exit /b 1
exit /b 0

:collect
rem copy (never move) the recipe job folder into out\recipe so the Board can bring it back (R334), check the copied export is
rem there, then write the last line; a failed copy or a missing export is reported and returns 1
set COLLECTFAIL=
if not exist "%V%\recipe\chorus_C12" (
  echo collect FAILED: no recipe\chorus_C12 folder >> "%RES%"
  set COLLECTFAIL=1
  goto collected
)
xcopy /e /i /y /q "%V%\recipe\chorus_C12" "%O%\recipe" >> "%O%\log_collect.txt" 2>&1
set XEL=%ERRORLEVEL%
echo collect exit %XEL% >> "%RES%"
if not "%XEL%"=="0" set COLLECTFAIL=1
if defined SHIPOK if not exist "%O%\recipe\export\B19_11\B19_11.glb" (
  echo collect FAILED: out\recipe\export\B19_11\B19_11.glb is missing >> "%RES%"
  set COLLECTFAIL=1
)
:collected
if defined SHIPFAIL set COLLECTFAIL=1
if defined COLLECTFAIL (echo done FAILED %DATE% %TIME% >> "%RES%") else (echo done %DATE% %TIME% >> "%RES%")
echo all done >> "%RES%"
if defined COLLECTFAIL exit /b 1
exit /b 0

:ship
rem one ship, in its own cmd (called above as: this file ship SHIP CODE); C, O, RES, GD, INSTALL_TO and RECIPE_NOPAUSE come
rem from the caller
set SHIP=%2
set CODE=%3
set CAMJ=
set FAILED=
set CHECKFAIL=
for %%S in (1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export) do call :stage %%S
if defined FAILED (
  echo %SHIP% checks SKIPPED: stage %FAILED% failed, so the installed glb is not this run's >> "%RES%"
  exit /b 1
)
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- %CODE% > "%O%\log_%SHIP%_readback_gpu.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% gpu readback exit %EL% >> "%RES%"
if not "%EL%"=="0" set CHECKFAIL=1
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --script res://fx/test/authored_interiors_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_%SHIP%_interiors.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% authored interiors exit %EL% >> "%RES%"
if not "%EL%"=="0" set CHECKFAIL=1
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_%SHIP%_death_seam.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% death seam exit %EL% >> "%RES%"
if defined CHECKFAIL exit /b 1
exit /b 0

:stage
if defined FAILED (
  echo %SHIP% %1 SKIPPED: stage %FAILED% failed >> "%RES%"
  exit /b 0
)
echo %SHIP% %1 start %TIME% >> "%RES%"
call "%C%\tools\recipe\%1.bat" > "%O%\log_%SHIP%_%1.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% %1 exit %EL% at %TIME% >> "%RES%"
if not "%EL%"=="0" set FAILED=%1
exit /b 0
