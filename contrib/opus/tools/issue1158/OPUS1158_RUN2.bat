@echo off
title S8 shorter spires rerun: stages 6 and 7, preview, isolated install, shots (issue 1158) - GPU job
rem Issue 1158 rerun. The first run (OPUS1158_RUN.bat) passed stages 1 to 5 at commit 02009810 but 6_lod and 7_export timed
rem out waiting for a GPU slot. This reuses that clone (opus1158\repo, same commit, not refetched, so it matches the stage 5
rem bake in recipe\voidsworn_S8) and runs 6_lod, 7_export with an isolated install into the clone's own godot folder (never
rem the shared build), the Blender preview of the painted ship, the Godot import, a4_shots cams for V1b_r_23 and the GPU
rem readback. A failed stage skips everything after it. Every step logs to opus1158\out\result.txt; the last line is
rem "all done". Writes only under opus1158\ and recipe\voidsworn_S8\. Never deletes anything.
setlocal
set PC_GPU_WAIT_SECONDS=3600
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1158
set C=%W%\repo
set O=%W%\out
set RES=%O%\result.txt
if not exist "%O%" mkdir "%O%"
echo rerun start %DATE% %TIME% >> "%RES%"
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set SHIP=voidsworn_S8
set RECIPE_NOPAUSE=1
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set JOB=%V%\recipe\voidsworn_S8
set INSTALL_TO=%C%\godot
set FAIL=
cd /d "%C%"
set HEAD=
for /f %%H in ('git -C "%C%" rev-parse HEAD') do set HEAD=%%H
if not "%HEAD%"=="0200981052b4d8b940fb12ccf44f7a3ce8aa26cd" set FAIL=checkout %HEAD% is not the stage 5 bake commit 0200981052b4
if not exist "%JOB%\S8.blend" set FAIL=no stage 5 blend
if not defined FAIL call :stage 6_lod
if not defined FAIL call :stage 7_export
if defined FAIL goto after_preview
echo preview start %TIME% >> "%RES%"
call "%C%\tools\pc\tmo.bat" 21600 "%B%" -b "%JOB%\S8.blend" -P "%C%\contrib\opus\tools\issue756\preview.py" -- "%O%\preview" samples=32 scale=0.5 > "%O%\log_preview.txt" 2>&1
set EC=%ERRORLEVEL%
echo preview exit %EC% at %TIME% >> "%RES%"
if not "%EC%"=="0" set FAIL=preview exit %EC%
:after_preview
if defined FAIL goto after_import
echo import start %TIME% >> "%RES%"
call "%C%\tools\pc\tmo.bat" 3600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
set EC=%ERRORLEVEL%
echo import exit %EC% at %TIME% >> "%RES%"
if not "%EC%"=="0" set FAIL=import exit %EC%
:after_import
if defined FAIL goto after_shots
echo shots start %TIME% >> "%RES%"
call "%C%\tools\pc\tmo.bat" 3600 "%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs voidsworn --sets cams --codes V1b_r_23 > "%O%\log_shots.txt" 2>&1
set EC=%ERRORLEVEL%
echo shots exit %EC% at %TIME% >> "%RES%"
if not "%EC%"=="0" set FAIL=shots exit %EC%
:after_shots
if defined FAIL goto after_readback
echo readback start %TIME% >> "%RES%"
call "%C%\tools\pc\tmo.bat" 3600 "%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- V1b_r_23 > "%O%\log_readback.txt" 2>&1
set EC=%ERRORLEVEL%
echo readback exit %EC% at %TIME% >> "%RES%"
if not "%EC%"=="0" set FAIL=readback exit %EC%
:after_readback
if defined FAIL echo skipped the rest after: %FAIL% >> "%RES%"
for %%F in (audit.json density.json S8.json licences.json lights.json log_audit.txt log_sheet_contract.txt log_bake.txt log_lod.txt log_godot.txt log_export.txt log_surface.txt) do if exist "%JOB%\%%F" copy /y "%JOB%\%%F" "%O%\" > nul
if not exist "%O%\surface" mkdir "%O%\surface"
if exist "%JOB%\surface" copy /y "%JOB%\surface\*.*" "%O%\surface\" > nul
if not exist "%O%\godot_bench" mkdir "%O%\godot_bench"
if exist "%JOB%\godot" copy /y "%JOB%\godot\*.*" "%O%\godot_bench\" > nul
if defined FAIL echo RUN2 FAILED: %FAIL% >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
if defined FAIL exit /b 1
exit /b 0
:stage
echo %1 start %TIME% >> "%RES%"
call "%C%\tools\recipe\%1.bat" > "%O%\log_%1_run2.txt" 2>&1
set EC=%ERRORLEVEL%
echo %1 exit %EC% at %TIME% >> "%RES%"
if not "%EC%"=="0" set FAIL=%1 exit %EC%
exit /b 0
