@echo off
title A16 and A17 painted through the recipe, stages 4 to 7 (issue 601) - GPU job
rem Issue 601: the Hullbreaker paint stack on both sheet ships (bake "stack"), from branch opus/issue-601 in opus601\repo (fetched
rem and reset to the branch head; cloned fresh if missing). For each ship: stages 4 to 7 (stage 4 again because both sheets'
rem insides moved in 417832ae; stages 1 to 3 outputs are already in recipe\<ship> from the 592 and 532 runs), with stage 5's
rem surface check; the install into the clone's own godot folder (what it replaces is copied aside first); a4_shots (battle,
rem close, cams: camera 170 and 60); the GPU readback; the painted sheet pictures beside the concept (paint_sheet.py on the GPU,
rem paint_compare.py). Each step is logged with its exit code in out\result.txt. Writes only under opus601\ and recipe\<ship>\.
rem Never deletes anything.
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus601
set C=%W%\repo
set O=%W%\out2
if not exist "%W%" mkdir "%W%"
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git clone -q --depth 1 --branch opus/issue-601 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin opus/issue-601 >> "%RES%" 2>&1
git -C "%C%" checkout -q -f FETCH_HEAD >> "%RES%" 2>&1
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set RECIPE_NOPAUSE=1
set INSTALL_TO=%C%\godot
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set BPY=%V%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe
cd /d "%C%"
"%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
call :ship corsair_A16 A16 C19_51
call :ship corsair_A17 A17 C15s_23
echo done %DATE% %TIME% >> "%RES%"
exit /b 0

:ship
set SHIP=%1
set CELLX=%2
set CODEX=%3
set JOBX=%V%\recipe\%1
set OS_=%O%\%2
if not exist "%OS_%" mkdir "%OS_%"
echo === %SHIP% %TIME% >> "%RES%"
for %%S in (4_parts_kit 5_paint_bake 6_lod 7_export) do call :stage %%S
"%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%OS_%\shots" --facs corsair --sets battle,close,cams --codes %CODEX% > "%OS_%\log_shots.txt" 2>&1
echo %SHIP% shots exit %ERRORLEVEL% >> "%RES%"
"%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- %CODEX% > "%OS_%\log_readback_gpu.txt" 2>&1
echo %SHIP% gpu readback exit %ERRORLEVEL% >> "%RES%"
"%B%" -b "%JOBX%\%CELLX%.blend" -P "%C%\tools\blender\build_sheets\paint_sheet.py" -- "%OS_%\paint" %SHIP% "%C%\contrib\muse\design\concept_round8_2026_11\%SHIP%_beauty.jpg" lift=1.25 samples=64 scale=1.0 gpu=1 > "%OS_%\log_paint_sheet.txt" 2>&1
echo %SHIP% paint sheet exit %ERRORLEVEL% >> "%RES%"
"%BPY%" "%C%\tools\blender\build_sheets\paint_compare.py" "%OS_%\paint" "%C%\contrib\muse\design\concept_round8_2026_11\%SHIP%_beauty.jpg" "%OS_%\shots" %CODEX% "%OS_%\pictures" name=%CELLX% > "%OS_%\log_compare.txt" 2>&1
echo %SHIP% compare exit %ERRORLEVEL% >> "%RES%"
findstr /c:"surface check" "%JOBX%\log_surface.txt" >> "%RES%" 2>&1
for %%F in (density.json %CELLX%.json licences.json lights.json log_surface.txt) do copy /y "%JOBX%\%%F" "%OS_%\" > nul
if not exist "%OS_%\surface" mkdir "%OS_%\surface"
copy /y "%JOBX%\surface\*.*" "%OS_%\surface\" > nul
exit /b 0

:stage
echo %SHIP% %1 start %TIME% >> "%RES%"
call "%C%\tools\recipe\%1.bat" > "%OS_%\log_%1.txt" 2>&1
echo %SHIP% %1 exit %ERRORLEVEL% at %TIME% >> "%RES%"
exit /b 0
