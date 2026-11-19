@echo off
title C14 (Chorus brood-sac carrier) through the recipe (issue 1155) - GPU job
rem Issue 1155: the Chorus brood-sac carrier chorus_C14 (data.js b_brood, game folder B22_11) through the ship recipe.
rem Two runs, one file (R334: the Board copies it to voidsworn_test\opus1155\OPUS1155_RUN.bat and queues each mode):
rem   OPUS1155_RUN.bat front   stages 1 to 4 (concept in, the AI shape reference, the outline fit, the sheet hull and its audit)
rem   OPUS1155_RUN.bat paint   stages 1 to 7 with PR 1083's branch merged (the Chorus paint stack, a labelled PREVIEW until it
rem                            merges; set PAINT_BASE=none to skip, or to another branch), the install into this job's own
rem                            clone, the GPU readback, the authored interiors check, the death seam check, and only when all of
rem                            those passed the in-game shots: battle, close (the blob sweep) and cams (camera 170 and 60).
rem Clones its own folder opus1155\repo on branch opus/issue-1155; writes only under opus1155\ and recipe\chorus_C14, deletes
rem nothing. An install replaces only the clone's own godot\assets\ships\B22_11 (copied aside first by stage 7).
rem Every step logs to opus1155\out\log_<mode>_<step>.txt. result.txt lists each exit code, then "done" or "done FAILED", then
rem "all done"; the file exits 1 on any failure (a git step, the paint merge, a stage, a check, the shots or the collect), so a
rem failed run never reads as a clean one (Artoo on PR 1172, Vigil's checked paths from 1157).
setlocal
set MODE=%1
if "%MODE%"=="" set MODE=front
set V=%USERPROFILE%\Downloads\voidsworn_test
set C=%V%\opus1155\repo
set O=%V%\opus1155\out
if not exist "%O%" mkdir "%O%"
set RES=%O%\result.txt
set RUNFAIL=
echo start %MODE% %DATE% %TIME% >> "%RES%"
if not exist "%C%\.git" git clone -q --depth 50 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
if not exist "%C%\.git" (
  echo git FAILED: could not clone the repo >> "%RES%"
  goto fail
)
git -C "%C%" fetch -q --depth 50 origin opus/issue-1155 >> "%RES%" 2>&1
if errorlevel 1 (
  echo git FAILED: could not fetch opus/issue-1155 >> "%RES%"
  goto fail
)
git -C "%C%" checkout -q -f -B run1155 FETCH_HEAD >> "%RES%" 2>&1
if errorlevel 1 (
  echo git FAILED: could not check out opus/issue-1155 >> "%RES%"
  goto fail
)
rem the paint run merges PR 1083's branch (the Chorus paint stack) unless PAINT_BASE says otherwise; PAINT_BASE=none skips it
if "%MODE%"=="paint" if "%PAINT_BASE%"=="" set PAINT_BASE=codex/issue-1058
if "%PAINT_BASE%"=="none" set PAINT_BASE=
if "%PAINT_BASE%"=="" goto merged
git -C "%C%" fetch -q --depth 50 origin %PAINT_BASE% >> "%RES%" 2>&1
if errorlevel 1 (
  echo git FAILED: could not fetch %PAINT_BASE% >> "%RES%"
  goto fail
)
git -C "%C%" -c user.name=opus1155 -c user.email=opus1155@localhost merge -q --no-edit FETCH_HEAD >> "%RES%" 2>&1
if errorlevel 1 (
  echo git FAILED: %PAINT_BASE% did not merge cleanly >> "%RES%"
  git -C "%C%" merge --abort >> "%RES%" 2>&1
  goto fail
)
echo merged %PAINT_BASE%: the paint is a PREVIEW of that branch's stack >> "%RES%"
:merged
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
set RECIPE_NOPAUSE=1
rem the GPU queue is shared by every helper: wait up to an hour for a GPU slot (gpu_slots.js caps it at 3600)
set PC_GPU_WAIT_SECONDS=3600
set INSTALL_TO=%C%\godot
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set SHIP=chorus_C14
set CODE=B22_11
set CAMJ=
set FAILED=
cd /d "%C%"
if "%MODE%"=="front" (
  for %%S in (1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit) do call :stage %%S
  goto collect
)
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_%MODE%_import.txt" 2>&1
set EL=%ERRORLEVEL%
echo import exit %EL% >> "%RES%"
if not "%EL%"=="0" set FAILED=import
for %%S in (1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export) do call :stage %%S
if defined FAILED (
  echo checks and shots SKIPPED: %FAILED% failed, so the installed glb is not this run's >> "%RES%"
  goto collect
)
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- %CODE% > "%O%\log_%MODE%_readback_gpu.txt" 2>&1
set EL=%ERRORLEVEL%
echo readback_gpu exit %EL% >> "%RES%"
if not "%EL%"=="0" if not defined FAILED set FAILED=readback_gpu
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --script res://fx/test/authored_interiors_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_%MODE%_interiors.txt" 2>&1
set EL=%ERRORLEVEL%
echo interiors exit %EL% >> "%RES%"
if not "%EL%"=="0" if not defined FAILED set FAILED=interiors
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\%CODE%\%CODE%.glb" > "%O%\log_%MODE%_death_seam.txt" 2>&1
set EL=%ERRORLEVEL%
echo death_seam exit %EL% >> "%RES%"
if not "%EL%"=="0" if not defined FAILED set FAILED=death_seam
if defined FAILED (
  echo shots SKIPPED: %FAILED% failed >> "%RES%"
  goto collect
)
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs chorus --sets battle,close,cams --codes %CODE% > "%O%\log_%MODE%_shots.txt" 2>&1
set EL=%ERRORLEVEL%
echo shots exit %EL% >> "%RES%"
if not "%EL%"=="0" if not defined FAILED set FAILED=shots

:collect
rem copy (never move) this run's recipe pictures and records into out\recipe_<mode> so the Board brings them back (R334)
if not exist "%V%\recipe\%SHIP%" (
  echo collect FAILED: no recipe\%SHIP% folder >> "%RES%"
  set FAILED=collect
  goto end
)
if not exist "%O%\recipe_%MODE%" mkdir "%O%\recipe_%MODE%"
xcopy /e /i /y /q "%V%\recipe\%SHIP%" "%O%\recipe_%MODE%" > "%O%\log_%MODE%_collect.txt" 2>&1
set EL=%ERRORLEVEL%
echo collect exit %EL% >> "%RES%"
if not "%EL%"=="0" set FAILED=collect
:end
if defined FAILED goto fail
echo %MODE% done %DATE% %TIME% >> "%RES%"
echo all done >> "%RES%"
exit /b 0

:fail
if not defined FAILED set FAILED=git
echo %MODE% done FAILED %FAILED% %DATE% %TIME% >> "%RES%"
echo all done >> "%RES%"
exit /b 1

:stage
if defined FAILED (
  echo %1 SKIPPED: %FAILED% failed >> "%RES%"
  exit /b 0
)
echo %1 start %TIME% >> "%RES%"
call "%C%\tools\recipe\%1.bat" > "%O%\log_%MODE%_%1.txt" 2>&1
set EL=%ERRORLEVEL%
echo %1 exit %EL% at %TIME% >> "%RES%"
if not "%EL%"=="0" set FAILED=%1
exit /b 0
