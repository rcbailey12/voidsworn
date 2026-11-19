@echo off
title Chorus armour R341: C11, C12, C13 export into the game (issue 1234) - GPU job
rem Issue 1234 (R341, Ryan accepted round 3 on Nov 19 2026, 23:38 UTC: "Accept, keep yellow-green glow"): the whole-body
rem armour shell from the shared Chorus kit on chorus_C11 (b_razor, B21_11), chorus_C12 (b_drone, B19_11) and chorus_C13
rem (b_spitter, B20_11), each through recipe stages 3 to 7 at the standard 4096 bake, installed into build\godot (the game).
rem   R341_EXPORT_1234.bat            all three ships, one after the other
rem   R341_EXPORT_1234.bat chorus_C12 one ship only
rem   FULL=1 reruns stages 1 and 2 as well (the concept and the shape reference do not change with the armour).
rem Clones its own folder opus1234\repo (shallow) on branch opus/issue-1234; writes only opus1234\, the recipe job folders
rem recipe\<ship>\ and, by stage 7's install, build\godot\assets\ships\<code>\ (the old files copied aside first by stage 7).
rem Nothing is deleted.
rem Throwaway profile guard (issue 1228): every program this job starts sees APPDATA and LOCALAPPDATA in opus1234\profile, so
rem a Godot run here can never rewrite Ryan's real settings (battle_opts.json and the rest of the game's user folder).
rem After the three installs: the GPU readback, the authored interiors and death seam checks, and the in-game shots at camera
rem 170 and close, for each installed ship, on build\godot. Every step logs to opus1234\out\<ship>\log_<step>.txt;
rem out\result.txt lists each exit code. A failed stage skips that ship's later stages and its checks; the other ships run.
rem Last line of result.txt: all done.
setlocal enabledelayedexpansion
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1234
set C=%W%\repo
set OUT=%W%\out
if not exist "%OUT%" mkdir "%OUT%"
set RES=%OUT%\result.txt
echo start %DATE% %TIME% > "%RES%"
if not exist "%C%\.git" git clone -q --depth 50 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 50 origin opus/issue-1234 >> "%RES%" 2>&1
git -C "%C%" checkout -q -B run1234 FETCH_HEAD >> "%RES%" 2>&1
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
rem the throwaway profile (after git, which reads its own settings from the real profile)
set "PROF=%W%\profile"
if not exist "%PROF%\Roaming" mkdir "%PROF%\Roaming"
if not exist "%PROF%\Local" mkdir "%PROF%\Local"
set "APPDATA=%PROF%\Roaming"
set "LOCALAPPDATA=%PROF%\Local"
echo profile guard APPDATA=%APPDATA% >> "%RES%"
set RECIPE_NOPAUSE=1
set PC_GPU_WAIT_SECONDS=3600
set PC_GPU_ISSUE=1234
set "GAME=%V%\build\godot"
if not exist "%GAME%\project.godot" (
  echo FAILED: no game project at %GAME% >> "%RES%"
  goto end
)
set INSTALL_TO=%GAME%
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set SHIPS=chorus_C11 chorus_C12 chorus_C13
if not "%1"=="" set SHIPS=%1
set STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export
if "%FULL%"=="1" set STAGES=1_concept_in 2_shape_ref %STAGES%
set DONE_CODES=
cd /d "%C%"
for %%P in (%SHIPS%) do call :ship %%P
if "%DONE_CODES%"=="" (
  echo checks SKIPPED: no ship installed >> "%RES%"
  goto end
)
rem the game project re-imports once with every new ship in it, then the checks run per installed ship
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%GAME%" --import > "%OUT%\log_import.txt" 2>&1
echo import exit %ERRORLEVEL% >> "%RES%"
for %%K in (%DONE_CODES%) do call :checks %%K
:end
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0

:ship
set SHIP=%1
set O=%OUT%\%SHIP%
if not exist "%O%" mkdir "%O%"
set FAILED=
set CODE=
if /i "%SHIP%"=="chorus_C11" set CODE=B21_11
if /i "%SHIP%"=="chorus_C12" set CODE=B19_11
if /i "%SHIP%"=="chorus_C13" set CODE=B20_11
if "%CODE%"=="" (
  echo %SHIP% FAILED: not one of chorus_C11, chorus_C12, chorus_C13 >> "%RES%"
  exit /b 0
)
echo %SHIP% ^(%CODE%^) start %TIME% >> "%RES%"
for %%S in (%STAGES%) do call :stage %%S
if defined FAILED (
  echo %SHIP% NOT INSTALLED: stage %FAILED% failed >> "%RES%"
  exit /b 0
)
set DONE_CODES=%DONE_CODES% %CODE%
echo %SHIP% installed as %CODE% >> "%RES%"
exit /b 0

:stage
if defined FAILED (
  echo %SHIP% %1 SKIPPED: stage %FAILED% failed >> "%RES%"
  exit /b 0
)
echo %SHIP% %1 start %TIME% >> "%RES%"
call "%C%\tools\recipe\%1.bat" > "%O%\log_%1.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% %1 exit %EL% at %TIME% >> "%RES%"
if not "%EL%"=="0" set FAILED=%1
exit /b 0

:checks
set K=%1
set O=%OUT%\checks_%K%
if not exist "%O%" mkdir "%O%"
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --path "%GAME%" --script res://render/test/installed_ship_check.gd -- %K% > "%O%\log_readback_gpu.txt" 2>&1
echo %K% gpu readback exit %ERRORLEVEL% >> "%RES%"
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%GAME%" --script res://fx/test/authored_interiors_check.gd -- "%GAME%\assets\ships\%K%\%K%.glb" > "%O%\log_interiors.txt" 2>&1
echo %K% authored interiors exit %ERRORLEVEL% >> "%RES%"
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%GAME%" --script res://fx/test/death_seam_check.gd -- "%GAME%\assets\ships\%K%\%K%.glb" > "%O%\log_death_seam.txt" 2>&1
echo %K% death seam exit %ERRORLEVEL% >> "%RES%"
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --path "%GAME%" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs chorus --sets battle,close --codes %K% > "%O%\log_shots.txt" 2>&1
echo %K% shots exit %ERRORLEVEL% >> "%RES%"
exit /b 0
