@echo off
title Chorus armour R341: C11, C12, C13 export into the game (issue 1234) - GPU job
rem Issue 1234 (R341, Ryan accepted round 3 on Nov 19 2026, 23:38 UTC: "Accept, keep yellow-green glow"): the whole-body
rem armour shell from the shared Chorus kit on chorus_C11 (b_razor, B21_11), chorus_C12 (b_drone, B19_11) and chorus_C13
rem (b_spitter, B20_11), each through recipe stages 3 to 7 at the standard 4096 bake, then into build\godot (the game).
rem   R341_EXPORT_1234.bat            all three ships
rem   R341_EXPORT_1234.bat chorus_C12 one ship only
rem   FULL=1 reruns stages 1 and 2 as well (the concept and the shape reference do not change with the armour).
rem   PIN=<commit> builds another commit; the default is the accepted round 3 commit below.
rem Two phases (Artoo's review on PR 1242):
rem   1. Stage: clone opus1234\repo at the pinned commit (stops if the fetch, checkout or commit check fails), run the stages
rem      with stage 7 installing into the clone's own godot project, import it once, then the GPU readback, authored
rem      interiors, death seam and in-game shots (camera 170 and close) for every ship. build\godot is not touched.
rem   2. Publish: only when every ship and every check passed, each checked export goes into build\godot through the shared
rem      stage 7 installer (snapshot, lock, backups, hash check, readback, old files restored on its own failure). Publish
rem      stops at the first failure and result.txt names the ships already live.
rem   Right after each ship's stage 7, its export is copied into this run's own folder opus1234\checked\<run>\<code>, and
rem   tools\recipe\staged_identity.py proves it is what stage 7 installed into the staging project (what the checks then
rem   read), both ways: the GLB, the same set of map files with the same bytes, and manifest_entry.json equal to the staged
rem   manifest row. Publish reruns that proof against the hashes recorded then and installs from the private copy, so a
rem   later build of the same ship in recipe\<ship>\ cannot slip in between the checks and the publish.
rem Writes only opus1234\, the recipe job folders recipe\<ship>\ and, in phase 2, build\godot\assets\ships\<code>\ and the
rem game's ship cache. Nothing is deleted.
rem Throwaway profile guard (issue 1228): every program this job starts sees APPDATA and LOCALAPPDATA in opus1234\profile, so
rem a Godot run here can never rewrite Ryan's real settings (battle_opts.json and the rest of the game's user folder).
rem Every step logs to opus1234\out\; result.txt lists each exit code and ends in "all done" with PASS or FAILED.
rem The job exits 0 only when everything passed and was published; otherwise 1.
setlocal enabledelayedexpansion
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1234
set C=%W%\repo
set OUT=%W%\out
if not exist "%OUT%" mkdir "%OUT%"
set RES=%OUT%\result.txt
set BAD=
echo start %DATE% %TIME% > "%RES%"
rem the accepted round 3 look (opus/issue-1234 15abb1fb) plus staged_identity.py: c4c80c82 changes nothing in the kits,
rem sheets or recipe stages after 15abb1fb, only docs, this file and that one new script
if "%PIN%"=="" set PIN=c4c80c82d59e2205725213ddcc0fe39d2889c0d5
if not exist "%C%\.git" (
  git clone -q --depth 1 --no-checkout https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
  if errorlevel 1 (
    echo FAILED: git clone >> "%RES%"
    goto fail
  )
)
git -C "%C%" fetch -q --depth 1 origin %PIN% >> "%RES%" 2>&1
if errorlevel 1 (
  echo FAILED: git fetch of %PIN% >> "%RES%"
  goto fail
)
git -C "%C%" checkout -q -f -B run1234 %PIN% >> "%RES%" 2>&1
if errorlevel 1 (
  echo FAILED: git checkout of %PIN% >> "%RES%"
  goto fail
)
set HEADSHA=
for /f "usebackq delims=" %%H in (`git -C "%C%" rev-parse HEAD`) do set HEADSHA=%%H
if /i not "%HEADSHA%"=="%PIN%" (
  echo FAILED: the clone is at %HEADSHA%, not %PIN% >> "%RES%"
  goto fail
)
echo commit=%HEADSHA% >> "%RES%"
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
  goto fail
)
set "STAGE_GAME=%C%\godot"
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set BPY=%V%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe
set TMO=%C%\tools\pc\tmo.bat
set SHIPS=chorus_C11 chorus_C12 chorus_C13
if not "%1"=="" set SHIPS=%1
set STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export
if "%FULL%"=="1" set STAGES=1_concept_in 2_shape_ref %STAGES%
set DONE=
set RUN=%DATE:~-4%%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%_%RANDOM%
set RUN=%RUN: =0%
set "CHECKED=%W%\checked\%RUN%"
mkdir "%CHECKED%"
echo checked copies in %CHECKED% >> "%RES%"
cd /d "%C%"

rem ---- phase 1: stage into the clone's own game project ----
set INSTALL_TO=%STAGE_GAME%
call "%TMO%" 21600 "%GD%" --headless --path "%STAGE_GAME%" --import > "%OUT%\log_import_before.txt" 2>&1
if errorlevel 1 (
  echo FAILED: first import of the staging project >> "%RES%"
  goto fail
)
for %%P in (%SHIPS%) do call :ship %%P
if defined BAD goto fail
call "%TMO%" 21600 "%GD%" --headless --path "%STAGE_GAME%" --import > "%OUT%\log_import.txt" 2>&1
set EL=%ERRORLEVEL%
echo staging import exit %EL% >> "%RES%"
if not "%EL%"=="0" (
  set BAD=1
  goto fail
)
for %%P in (%DONE%) do call :checks %%P
if defined BAD goto fail

rem ---- phase 2: publish the checked exports into build\godot ----
set LIVE=
for %%P in (%DONE%) do (
  if not defined BAD call :publish %%P
)
if defined BAD (
  echo PUBLISH STOPPED: live in build\godot from this run:%LIVE% >> "%RES%"
  goto fail
)
echo published into build\godot:%LIVE% >> "%RES%"
echo all done PASS %DATE% %TIME% >> "%RES%"
exit /b 0

:fail
echo all done FAILED, build\godot changed only for:%LIVE% %DATE% %TIME% >> "%RES%"
exit /b 1

:ship
set SHIP=%1
set CODE=
if /i "%SHIP%"=="chorus_C11" set CODE=B21_11
if /i "%SHIP%"=="chorus_C12" set CODE=B19_11
if /i "%SHIP%"=="chorus_C13" set CODE=B20_11
if "%CODE%"=="" (
  echo %SHIP% FAILED: not one of chorus_C11, chorus_C12, chorus_C13 >> "%RES%"
  set BAD=1
  exit /b 0
)
set O=%OUT%\%SHIP%
if not exist "%O%" mkdir "%O%"
set FAILED=
echo %SHIP% ^(%CODE%^) start %TIME% >> "%RES%"
for %%S in (%STAGES%) do call :stage %%S
if defined FAILED (
  echo %SHIP% FAILED: stage %FAILED% >> "%RES%"
  set BAD=1
  exit /b 0
)
rem keep the exact staged bytes: copy the export, then every file must match what stage 7 installed for the checks
set "SNAP=%CHECKED%\%CODE%"
xcopy /e /i /q /y "%V%\recipe\%SHIP%\export\%CODE%" "%SNAP%" > "%O%\log_snapshot.txt" 2>&1
if errorlevel 1 (
  echo %SHIP% FAILED: could not copy the export aside >> "%RES%"
  set BAD=1
  exit /b 0
)
"%BPY%" -B "%C%\tools\recipe\staged_identity.py" "%SNAP%" "%STAGE_GAME%" %CODE% "%SNAP%.identity.json" > "%O%\log_identity.txt" 2>&1
if errorlevel 1 (
  type "%O%\log_identity.txt" >> "%RES%"
  echo %SHIP% FAILED: the export copied aside is not what stage 7 installed for the checks >> "%RES%"
  set BAD=1
  exit /b 0
)
type "%O%\log_identity.txt" >> "%RES%"
set DONE=%DONE% %SHIP%
echo %SHIP% staged as %CODE% >> "%RES%"
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

:code
set CODE=
if /i "%1"=="chorus_C11" set CODE=B21_11
if /i "%1"=="chorus_C12" set CODE=B19_11
if /i "%1"=="chorus_C13" set CODE=B20_11
exit /b 0

:checks
call :code %1
set K=%CODE%
set O=%OUT%\checks_%K%
if not exist "%O%" mkdir "%O%"
call "%TMO%" 21600 "%GD%" --path "%STAGE_GAME%" --script res://render/test/installed_ship_check.gd -- %K% > "%O%\log_readback_gpu.txt" 2>&1
call :mark %K% "gpu readback" %ERRORLEVEL%
call "%TMO%" 21600 "%GD%" --headless --path "%STAGE_GAME%" --script res://fx/test/authored_interiors_check.gd -- "%STAGE_GAME%\assets\ships\%K%\%K%.glb" > "%O%\log_interiors.txt" 2>&1
call :mark %K% "authored interiors" %ERRORLEVEL%
call "%TMO%" 21600 "%GD%" --headless --path "%STAGE_GAME%" --script res://fx/test/death_seam_check.gd -- "%STAGE_GAME%\assets\ships\%K%\%K%.glb" > "%O%\log_death_seam.txt" 2>&1
call :mark %K% "death seam" %ERRORLEVEL%
call "%TMO%" 21600 "%GD%" --path "%STAGE_GAME%" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs chorus --sets battle,close --codes %K% > "%O%\log_shots.txt" 2>&1
call :mark %K% "shots" %ERRORLEVEL%
exit /b 0

:mark
set EL=%3
echo %1 %~2 exit %EL% >> "%RES%"
if not "%EL%"=="0" set BAD=1
exit /b 0

:publish
set SHIP=%1
call :code %SHIP%
set "JOB=%V%\recipe\%SHIP%"
set "SNAP=%CHECKED%\%CODE%"
"%BPY%" -B "%C%\tools\recipe\staged_identity.py" "%SNAP%" "%STAGE_GAME%" %CODE% "%SNAP%.identity.json" --expect > "%OUT%\log_identity_publish_%CODE%.txt" 2>&1
if errorlevel 1 (
  type "%OUT%\log_identity_publish_%CODE%.txt" >> "%RES%"
  echo %SHIP% publish REFUSED: the checked copy of %CODE% changed since the checks >> "%RES%"
  set BAD=1
  exit /b 0
)
"%BPY%" -B "%C%\tools\recipe\manifest_merge.py" --install "%SNAP%" "%GAME%" "%CODE%" "%GD%" "%JOB%" "%C%\tools\recipe\ships\%SHIP%.json" > "%OUT%\log_publish_%CODE%.txt" 2>&1
set EL=%ERRORLEVEL%
echo %SHIP% publish %CODE% exit %EL% >> "%RES%"
if not "%EL%"=="0" (
  set BAD=1
  exit /b 0
)
set LIVE=%LIVE% %CODE%
exit /b 0
