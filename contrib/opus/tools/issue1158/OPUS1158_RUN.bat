@echo off
title S8 shorter spires, stages 1 to 7 and pictures (issue 1158) - GPU job
rem Issue 1158 (R331): the S8 Daybreak's seven radiator spires at 70 percent, ember in the fin slats. Fresh clone of branch
rem opus/issue-1158 in opus1158\repo; recipe stages 1 to 7 for voidsworn_S8 (JOB is recipe\voidsworn_S8 and bakeoff\voidsworn_S8_trellis.glb, both new for this job);
rem then an isolated install into the clone's own godot folder only (never the shared build: the Board says yes first),
rem a4_shots cams for V1b_r_23 there, the GPU readback, and the issue 756 Blender previews of the painted ship (battle camera,
rem spires close, the concept camera). Each step logs its exit code in out\result.txt. Writes only under opus1158\ and
rem recipe\voidsworn_S8\. Never deletes anything.
setlocal
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1158
set C=%W%\repo
set O=%W%\out
if not exist "%W%" mkdir "%W%"
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
echo start %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git -c core.autocrlf=false clone -q --depth 1 --branch opus/issue-1158 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin opus/issue-1158 >> "%RES%" 2>&1
git -C "%C%" checkout -q FETCH_HEAD >> "%RES%" 2>&1
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set SHIP=voidsworn_S8
set RECIPE_NOPAUSE=1
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set BPY=%V%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe
set JOB=%V%\recipe\voidsworn_S8
cd /d "%C%"
for %%S in (1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export) do call :stage %%S
call "%C%\tools\pc\tmo.bat" 21600 "%B%" -b "%JOB%\S8.blend" -P "%C%\contrib\opus\tools\issue756\preview.py" -- "%O%\preview" samples=32 scale=0.5 > "%O%\log_preview.txt" 2>&1
echo preview exit %ERRORLEVEL% >> "%RES%"
set INSTALL_TO=%C%\godot
echo 7_export install start %TIME% >> "%RES%"
call "%C%\tools\recipe\7_export.bat" > "%O%\log_7_install.txt" 2>&1
echo 7_export install exit %ERRORLEVEL% at %TIME% >> "%RES%"
call "%C%\tools\pc\tmo.bat" 3600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
call "%C%\tools\pc\tmo.bat" 3600 "%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs voidsworn --sets cams --codes V1b_r_23 > "%O%\log_shots.txt" 2>&1
echo shots exit %ERRORLEVEL% >> "%RES%"
call "%C%\tools\pc\tmo.bat" 3600 "%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- V1b_r_23 > "%O%\log_readback_gpu.txt" 2>&1
echo gpu readback exit %ERRORLEVEL% >> "%RES%"
for %%F in (audit.json density.json S8.json licences.json lights.json log_build.txt log_audit.txt log_sheet_contract.txt log_bake.txt log_export.txt) do if exist "%JOB%\%%F" copy /y "%JOB%\%%F" "%O%\" > nul
if not exist "%O%\surface" mkdir "%O%\surface"
if exist "%JOB%\surface" copy /y "%JOB%\surface\*.*" "%O%\surface\" > nul
echo done %DATE% %TIME% >> "%RES%"
exit /b 0
:stage
echo %1 start %TIME% >> "%RES%"
call "%C%\tools\recipe\%1.bat" > "%O%\log_%1.txt" 2>&1
echo %1 exit %ERRORLEVEL% at %TIME% >> "%RES%"
exit /b 0
