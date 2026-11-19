@echo off
rem Issue 1174: the one shared ship build job. Every helper's ship run is a three-line wrapper that sets the inputs and calls
rem this file (docs/ship_pipeline/ship_job/README.md). Built from issue 1157's S10_RUN_1157.bat, the best guarded job of Nov 19.
rem
rem Inputs (environment, set by the wrapper):
rem   SHIP        the recipe ship id, the file name in tools\recipe\ships without .json (voidsworn_S10)
rem   CODE        the game folder the install writes (V16_37)
rem   BRANCH      the branch to build (opus/issue-1157)
rem   JOB_DIR     this job's own folder under Downloads\voidsworn_test (opus1157)
rem   STAGES      optional: the recipe stages, in order (default 1_concept_in to 7_export, all seven)
rem   SETS        optional: the a4_shots sets (default battle,close)
rem   FACS        optional: the a4_shots faction (default the part of SHIP before its first underscore)
rem   PAINT_BASE  optional: a branch merged in after the checkout; the pictures are then a labelled PREVIEW of that stack
rem   PC_GPU_WAIT_SECONDS  optional: how long each GPU step waits for its claim (default 3600, the most gpu_slots.js
rem               allows; the old 300 s default failed 1155, 1157 and 1158 on Nov 19 when several helpers queued at once)
rem
rem What it does, in order. Any failure skips every later step, the checks and the shots (the recipe folder is still copied
rem back, step 7, for the logs), and the last two lines of out\result.txt are always "done PASS" or "done FAILED: <step>" and then "all done".
rem   1. runs from its own copy in JOB_DIR (cmd reads a .bat as it goes, so a checkout must never rewrite the running file)
rem   2. its own clone JOB_DIR\repo (depth 50), the branch checked out (install files reset after a
rem      saved diff; any other local change stops the job), PAINT_BASE merged if set, a commit= line
rem   3. the headless import, then each stage logged with its exit code (stage 7 installs into the clone's own godot folder,
rem      never into Ryan's game)
rem   4. the installed glb must be this run's (written after the run started), else the install counts as failed
rem   5. the GPU readback, the authored interiors check and the death seam check on the installed glb; all three must pass
rem   6. the in-game shots at camera 170 and 60, only when everything above passed
rem   7. the recipe folder copied (never moved) into out\recipe
rem Writes only under voidsworn_test\JOB_DIR and voidsworn_test\recipe\SHIP (the stages' own folder). Deletes nothing: an earlier
rem run's out folder is renamed out_before_<time>, never removed.
if "%~1"=="ship" goto ship
setlocal EnableExtensions
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set MISSING=
if not defined SHIP set MISSING=SHIP
if not defined CODE set MISSING=%MISSING% CODE
if not defined BRANCH set MISSING=%MISSING% BRANCH
if not defined JOB_DIR set MISSING=%MISSING% JOB_DIR
if defined MISSING (
  echo ship_job.bat: set %MISSING% first. See docs\ship_pipeline\ship_job\README.md for the three-line wrapper.
  exit /b 2
)
set "J=%V%\%JOB_DIR%"
if not exist "%J%" mkdir "%J%"
rem 1. run from this job's own copy
if /i not "%~f0"=="%J%\ship_job_running.bat" (
  copy /y "%~f0" "%J%\ship_job_running.bat" > nul
  call "%J%\ship_job_running.bat"
  exit /b
)
if not defined STAGES set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
if not defined SETS set "SETS=battle,close"
if not defined FACS for /f "delims=_" %%F in ("%SHIP%") do set "FACS=%%F"
if not defined PC_GPU_WAIT_SECONDS set PC_GPU_WAIT_SECONDS=3600
if not defined PC_GPU_ISSUE set "PC_GPU_ISSUE=%JOB_DIR%"
set "C=%J%\repo"
set "O=%J%\out"
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd_HHmmss')"`) do set "STAMP=%%T"
if exist "%O%" ren "%O%" "out_before_%STAMP%"
mkdir "%O%"
set "RES=%O%\result.txt"
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "[DateTime]::UtcNow.Ticks"`) do set "START_TICKS=%%T"
echo start %SHIP% %CODE% %BRANCH% %DATE% %TIME% > "%RES%"
echo inputs STAGES=%STAGES% SETS=%SETS% FACS=%FACS% PAINT_BASE=%PAINT_BASE% PC_GPU_WAIT_SECONDS=%PC_GPU_WAIT_SECONDS% >> "%RES%"
if exist "%J%\out_before_%STAMP%" echo the earlier run's out folder is now out_before_%STAMP% >> "%RES%"
set FAILED=
set "GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe"

rem 2. own clone, the branch, PAINT_BASE
if not exist "%C%\.git" git clone -q --depth 50 https://github.com/rcbailey12/voidsworn "%C%" >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 50 origin %BRANCH% >> "%RES%" 2>&1
if errorlevel 1 set "FAILED=fetch %BRANCH%"
if defined FAILED goto collect
rem a forced checkout, in this job's own clone only, and only over what the install writes: stage 7 rewrites the tracked
rem godot\assets\ships files here (manifest.json, the CODE folder), and a plain checkout then refuses every rerun after the
rem branch moved. Every local change is saved first (clone_changes_before_checkout.patch, binary diff). A change anywhere
rem else (a hand fix in the clone) stops the job instead: nothing outside the install is ever thrown away (Artoo, PR 1179).
git -C "%C%" status --porcelain --untracked-files=no > "%O%\clone_changes_before_checkout.txt" 2> "%O%\log_clone_status.txt"
git -C "%C%" diff --binary HEAD > "%O%\clone_changes_before_checkout.patch" 2>> "%O%\log_clone_status.txt"
findstr /v /r /c:"^.. godot/assets/ships/" "%O%\clone_changes_before_checkout.txt" > "%O%\clone_changes_unexpected.txt"
for %%Z in ("%O%\clone_changes_unexpected.txt") do if %%~zZ GTR 0 set "FAILED=checkout: the clone has local changes outside godot\assets\ships, listed in clone_changes_unexpected.txt and saved in clone_changes_before_checkout.patch; nothing was reset"
if defined FAILED goto collect
for %%Z in ("%O%\clone_changes_before_checkout.txt") do if %%~zZ GTR 0 echo forced checkout: resetting the clone's install files listed in clone_changes_before_checkout.txt, saved first in clone_changes_before_checkout.patch >> "%RES%"
git -C "%C%" checkout -q -f -B shipjob FETCH_HEAD >> "%RES%" 2>&1
if errorlevel 1 set "FAILED=checkout %BRANCH%"
if defined FAILED goto collect
if not defined PAINT_BASE goto based
git -C "%C%" fetch -q --depth 50 origin %PAINT_BASE% >> "%RES%" 2>&1
if errorlevel 1 set "FAILED=fetch PAINT_BASE %PAINT_BASE%"
if defined FAILED goto collect
git -C "%C%" -c user.name=%JOB_DIR% -c user.email=%JOB_DIR%@localhost merge -q --no-edit FETCH_HEAD >> "%RES%" 2>&1
if errorlevel 1 set "FAILED=merge PAINT_BASE %PAINT_BASE%"
if defined FAILED git -C "%C%" merge --abort >> "%RES%" 2>&1
if defined FAILED goto collect
echo merged %PAINT_BASE%: the pictures of this run are a PREVIEW of that paint stack >> "%RES%"
:based
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1

rem 3. import, then the stages, each in a fresh cmd so the variables the stages set end with them
cd /d "%C%"
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
set EL=%ERRORLEVEL%
echo import exit %EL% >> "%RES%"
if not "%EL%"=="0" set "FAILED=import"
if defined FAILED goto collect
cmd /c ""%~f0" ship"
set EL=%ERRORLEVEL%
echo stages exit %EL% >> "%RES%"
if not "%EL%"=="0" set "FAILED=a stage (see the SKIPPED line above)"
if defined FAILED goto collect
echo %STAGES% | findstr /c:"7_export" > nul
if errorlevel 1 (
  echo checks and shots SKIPPED: STAGES has no 7_export, so nothing was installed >> "%RES%"
  goto collect
)

rem 4. the installed glb must be this run's
set "GLB=%C%\godot\assets\ships\%CODE%\%CODE%.glb"
powershell -NoProfile -Command "$f = Get-Item -LiteralPath $env:GLB -ErrorAction SilentlyContinue; if (-not $f -or $f.LastWriteTimeUtc.Ticks -lt [long]$env:START_TICKS) { exit 1 }"
if errorlevel 1 set "FAILED=install (%CODE%.glb missing or older than this run)"
if defined FAILED goto collect
echo install fresh: %GLB% >> "%RES%"

rem 5. the three checks on the installed glb; every one must pass
set CHECKFAIL=
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- %CODE% > "%O%\log_readback_gpu.txt" 2>&1
set EL=%ERRORLEVEL%
echo gpu readback exit %EL% >> "%RES%"
if not "%EL%"=="0" set "CHECKFAIL=%CHECKFAIL% readback"
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --script res://fx/test/authored_interiors_check.gd -- "%GLB%" > "%O%\log_interiors.txt" 2>&1
set EL=%ERRORLEVEL%
echo authored interiors exit %EL% >> "%RES%"
if not "%EL%"=="0" set "CHECKFAIL=%CHECKFAIL% interiors"
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%GLB%" > "%O%\log_death_seam.txt" 2>&1
set EL=%ERRORLEVEL%
echo death seam exit %EL% >> "%RES%"
if not "%EL%"=="0" set "CHECKFAIL=%CHECKFAIL% death_seam"
if defined CHECKFAIL set "FAILED=checks:%CHECKFAIL%"
if defined FAILED goto collect

rem 6. the shots, only now: everything above passed, so the installed glb is this run's and checked
call "%C%\tools\pc\tmo.bat" 21600 "%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs %FACS% --sets %SETS% --codes %CODE% > "%O%\log_shots.txt" 2>&1
set EL=%ERRORLEVEL%
echo shots exit %EL% >> "%RES%"
if not "%EL%"=="0" set "FAILED=shots"

rem 7. copy (never move) the recipe folder into out\recipe, so the Board can bring it back (R334)
:collect
if not exist "%V%\recipe\%SHIP%" (
  echo collect: no recipe\%SHIP% folder >> "%RES%"
  if not defined FAILED set "FAILED=collect (no recipe\%SHIP% folder)"
  goto finish
)
xcopy /e /i /y /q "%V%\recipe\%SHIP%" "%O%\recipe" > "%O%\log_collect.txt" 2>&1
set EL=%ERRORLEVEL%
echo collect exit %EL% >> "%RES%"
if not "%EL%"=="0" if not defined FAILED set "FAILED=collect"
echo %STAGES% | findstr /c:"7_export" > nul
if errorlevel 1 goto finish
if not exist "%O%\recipe\export\%CODE%\%CODE%.glb" if not defined FAILED set "FAILED=collect (out\recipe\export\%CODE%\%CODE%.glb missing)"

:finish
rem no parenthesised block here: FAILED can hold a ")" that would end the block early
if defined FAILED goto finish_failed
echo done PASS %DATE% %TIME% >> "%RES%"
echo all done >> "%RES%"
exit /b 0
:finish_failed
echo done FAILED: %FAILED% %DATE% %TIME% >> "%RES%"
echo all done >> "%RES%"
exit /b 1

:ship
rem the stages, in their own cmd (called above as: this file ship); SHIP, C, O, RES and STAGES come from the caller
set RECIPE_NOPAUSE=1
set "INSTALL_TO=%C%\godot"
set CAMJ=
set FAILED=
for %%S in (%STAGES%) do call :stage %%S
if defined FAILED (
  echo checks and shots SKIPPED: stage %FAILED% failed, so the installed glb is not this run's >> "%RES%"
  exit /b 1
)
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
