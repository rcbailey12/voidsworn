@echo off
title A16 painted through the recipe, stages 5 to 7 (issue 601) - GPU job
rem Issue 601: the Hullbreaker paint stack on A16 (bake "stack"), from a fresh clone of branch opus/issue-601, modelled on
rem A16_RUN_592b.bat. Stages 1 to 4 are not rerun: their outputs for corsair_A16 are already in recipe\corsair_A16 from the 592
rem runs (the sheet's design is unchanged on this branch; stage 5 rebuilds the same sheet through sheet_hull). Then the game
rem install (INSTALL_TO, the clone's own godot folder), a4_shots (battle, close, and cams: camera 170 and 60), the GPU readback,
rem and the painted sheet pictures beside the concept (paint_sheet.py on the GPU, paint_compare.py). Each step is logged with its
rem exit code in out\result.txt. Writes only under opus601\ and recipe\corsair_A16\. Never deletes anything.
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus601
set C=%W%\repo
set O=%W%\out
if not exist "%W%" mkdir "%W%"
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git clone -q --depth 1 --branch opus/issue-601 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin opus/issue-601 >> "%RES%" 2>&1
git -C "%C%" checkout -q FETCH_HEAD >> "%RES%" 2>&1
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set SHIP=corsair_A16
set RECIPE_NOPAUSE=1
set INSTALL_TO=%C%\godot
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set BPY=%V%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe
set JOB=%V%\recipe\corsair_A16
cd /d "%C%"
"%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
for %%S in (5_paint_bake 6_lod 7_export) do call :stage %%S
"%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs corsair --sets battle,close,cams --codes C19_51 > "%O%\log_shots.txt" 2>&1
echo shots exit %ERRORLEVEL% >> "%RES%"
"%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- C19_51 > "%O%\log_readback_gpu.txt" 2>&1
echo gpu readback exit %ERRORLEVEL% >> "%RES%"
"%B%" -b "%JOB%\A16.blend" -P "%C%\tools\blender\build_sheets\paint_sheet.py" -- "%O%\paint" corsair_A16 "%C%\contrib\muse\design\concept_round8_2026_11\corsair_A16_beauty.jpg" lift=1.25 samples=64 scale=1.0 gpu=1 > "%O%\log_paint_sheet.txt" 2>&1
echo paint sheet exit %ERRORLEVEL% >> "%RES%"
"%BPY%" "%C%\tools\blender\build_sheets\paint_compare.py" "%O%\paint" "%C%\contrib\muse\design\concept_round8_2026_11\corsair_A16_beauty.jpg" "%O%\shots" C19_51 "%O%\pictures" > "%O%\log_compare.txt" 2>&1
echo compare exit %ERRORLEVEL% >> "%RES%"
copy /y "%JOB%\density.json" "%O%\" > nul
copy /y "%JOB%\A16.json" "%O%\" > nul
copy /y "%JOB%\licences.json" "%O%\" > nul
echo done %DATE% %TIME% >> "%RES%"
exit /b 0
:stage
echo %1 start %TIME% >> "%RES%"
call "%C%\tools\recipe\%1.bat" > "%O%\log_%1.txt" 2>&1
echo %1 exit %ERRORLEVEL% at %TIME% >> "%RES%"
exit /b 0
