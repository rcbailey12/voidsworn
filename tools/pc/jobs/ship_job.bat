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
rem What it does, in order. Any failure skips the remaining build steps (step 7 still collects logs and other deliverables),
rem and the last two lines of out\result.txt are "done PASS" or "done FAILED: <step>" and then "all done".
rem   1. runs from its own copy in JOB_DIR (cmd reads a .bat as it goes, so a checkout must never rewrite the running file)
rem   2. its own clone JOB_DIR\repo from the shared mirror, the branch checked out (install files restored after a
rem      saved diff, never a forced checkout; any other local change or file collision stops the job), PAINT_BASE merged if set, a commit= line
rem   3. the headless import, then each stage logged with its exit code (stage 7 installs into the clone's own godot folder,
rem      never into Ryan's game)
rem   4. the installed glb must be this run's (written after the run started), else the install counts as failed
rem   5. the GPU readback, the authored interiors check and the death seam check on the installed glb; all three must pass
rem   6. the in-game shots at camera 170 and 60, only when everything above passed
rem   7. logs, reports, shots and export\CODE copied into out\recipe
rem The earlier out folder becomes out_before_<time>. Backups older than the newest two are listed for the janitor.
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
rem Nov 19 chain 1119B: a wrapper's inputs, STAGES above all, stayed set in the calling chain and the next ship ran
rem with them; 1157 and 1183 started at stage 4 with no stage 1 to 3 outputs. The launcher clears them in the caller on exit.
if /i not "%~f0"=="%J%\ship_job_running.bat" (
  copy /y "%~f0" "%J%\ship_job_running.bat" > nul || exit /b 1
  call "%J%\ship_job_running.bat"
  if errorlevel 1 endlocal & set "SHIP=" & set "CODE=" & set "BRANCH=" & set "JOB_DIR=" & set "STAGES=" & set "SETS=" & set "FACS=" & set "PAINT_BASE=" & set "PC_GPU_ISSUE=" & exit /b 1
  endlocal & set "SHIP=" & set "CODE=" & set "BRANCH=" & set "JOB_DIR=" & set "STAGES=" & set "SETS=" & set "FACS=" & set "PAINT_BASE=" & set "PC_GPU_ISSUE=" & exit /b 0
)
if not defined STAGES set "STAGES=1_concept_in 2_shape_ref 3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export"
if not defined SETS set "SETS=battle,close"
if not defined FACS for /f "delims=_" %%F in ("%SHIP%") do set "FACS=%%F"
if not defined PC_GPU_WAIT_SECONDS set PC_GPU_WAIT_SECONDS=3600
if not defined PC_GPU_ISSUE set "PC_GPU_ISSUE=%JOB_DIR%"
rem The Nov 19 cold Godot imports on this PC took up to about 1150 s (opus1077\out\log_import.txt).
set "SHIP_IMPORT_CAP=2400"
set "SHIP_CHECK_CAP=600"
set "SHIP_SHOTS_CAP=600"
set "C=%J%\repo"
set "O=%J%\out"
set "STAMP="
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd_HHmmss_fffffff')"`) do set "STAMP=%%T"
if exist "%O%" (
  if not defined STAMP exit /b 1
  ren "%O%" "out_before_%STAMP%" || exit /b 1
)
mkdir "%O%" || exit /b 1
set "RES=%O%\result.txt"
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "[DateTime]::UtcNow.Ticks"`) do set "START_TICKS=%%T"
set FAILED=
rem The installed copy runs on its own. Keep its inherited tool scratch under a named, owned TEMP directory.
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $id=[guid]::NewGuid().ToString('N'); $dir=Join-Path $env:TEMP ('voidsworn-run-' + $id); $null=[IO.Directory]::CreateDirectory($dir); [IO.File]::WriteAllText((Join-Path $dir '.voidsworn-run-owner'),$id); $dir" > "%O%\scratch_path.txt" 2>> "%RES%"
if errorlevel 1 set "FAILED=private TEMP setup"
if defined FAILED goto collect
set "BASE_TEMP=%TEMP%"
set /p TEMP=<"%O%\scratch_path.txt"
set "TMP=%TEMP%"
set "TMPDIR=%TEMP%"
rem The redirection holds the marker open until the tools finish.
call :run_tools 9>"%TEMP%\.voidsworn-run-active"
set "RUN_EL=%ERRORLEVEL%"
rem (1180) The scratch goes on PASS; on FAILED the newest one per job stays a day (tools_live scratch_done.ps1).
set "RUN_SCRATCH=%TEMP%"
set "TEMP=%BASE_TEMP%"
set "TMP=%BASE_TEMP%"
set "TMPDIR=%BASE_TEMP%"
set "SD_TLV="
if exist "%V%\tools_live\current.txt" set /p SD_TLV=<"%V%\tools_live\current.txt"
if defined SD_TLV if exist "%V%\tools_live\%SD_TLV%\pc\scratch_done.ps1" powershell -NoProfile -ExecutionPolicy Bypass -File "%V%\tools_live\%SD_TLV%\pc\scratch_done.ps1" -Scratch "%RUN_SCRATCH%" -Code %RUN_EL% -BaseTemp "%BASE_TEMP%" -JobKey "ship_job %J%" >> "%RES%" 2>&1
exit /b %RUN_EL%

:run_tools
echo start %SHIP% %CODE% %BRANCH% %DATE% %TIME% > "%RES%"
echo inputs STAGES=%STAGES% SETS=%SETS% FACS=%FACS% PAINT_BASE=%PAINT_BASE% PC_GPU_WAIT_SECONDS=%PC_GPU_WAIT_SECONDS% >> "%RES%"
if exist "%J%\out_before_%STAMP%" echo the earlier run's out folder is now out_before_%STAMP% >> "%RES%"
set "GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe"
rem (1194) The installed main watchdog in tools_live, never the job clone's own copy. Once tools_live is installed, a
rem blank pointer or a version without a watchdog fails the job before any step (fail closed, Artoo on PR 1254).
set "TMO=%C%\tools\pc\tmo.bat"
set "TLV="
if exist "%V%\tools_live\current.txt" set /p TLV=<"%V%\tools_live\current.txt"
set "TMO_OK="
if defined TLV if exist "%V%\tools_live\%TLV%\pc\run_timeout.ps1" set "TMO_OK=1"
if defined TMO_OK set "TMO=%V%\tools_live\%TLV%\pc\tmo.bat"
echo watchdog %TMO% >> "%RES%"
set "RECIPE=%V%\recipe\%SHIP%"

rem Keep the newest two out_before folders out of the janitor list. Listing carries no permission to delete.
powershell -NoProfile -Command "$ErrorActionPreference = 'Stop'; Get-ChildItem -LiteralPath $env:J -Directory -Filter 'out_before_*' | Sort-Object Name -Descending | Select-Object -Skip 2 -ExpandProperty FullName" > "%O%\out_before_for_janitor.txt" 2>> "%RES%"
if errorlevel 1 set "FAILED=could not list old out folders for the janitor"
if exist "%V%\tools_live\" if not defined TMO_OK set "FAILED=tools_live is installed but names no usable watchdog"
if defined FAILED goto collect

rem 2. Own clone and branch fetches. Use the same mirror lock as runner_common.ps1 around refresh and local Git reads.
set "MIRROR=%V%\repo-mirror.git"
powershell -NoProfile -Command ^
  "$ErrorActionPreference = 'Stop'; $mirror = $env:MIRROR; $source = 'https://github.com/rcbailey12/voidsworn';" ^
  "function Run-Git { & git.exe @args; if ($LASTEXITCODE -ne 0) { throw ('git failed: ' + ($args -join ' ')) } }" ^
  "$lock = $null; $deadline = [DateTime]::UtcNow.AddMinutes(30);" ^
  "while (-not $lock) { try { $lock = [IO.File]::Open($mirror + '.lock', 'OpenOrCreate', 'ReadWrite', 'None') }" ^
  "  catch [IO.IOException] { if ([DateTime]::UtcNow -ge $deadline) { throw 'shared repo copy stayed locked for 30 minutes' }; Start-Sleep -Milliseconds 500 } }" ^
  "try {" ^
  "  if (-not (Test-Path -LiteralPath (Join-Path $mirror 'HEAD'))) { Run-Git init --bare $mirror; Run-Git --git-dir $mirror remote add --mirror=fetch origin $source }" ^
  "  if ((Run-Git --git-dir $mirror config --get remote.origin.url) -ne $source) { throw 'shared repo copy has an unexpected origin; kept unchanged' }" ^
  "  Write-Output ('refreshing shared mirror ' + $mirror);" ^
  "  Run-Git --git-dir $mirror -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 fetch --prune origin;" ^
  "  Run-Git --git-dir $mirror symbolic-ref HEAD refs/heads/main;" ^
  "  if (-not (Test-Path -LiteralPath (Join-Path $env:C '.git'))) { Write-Output ('local clone ' + $env:C); Run-Git -c core.autocrlf=false clone --local -q $mirror $env:C }" ^
  "  $depth = @(); if ((Run-Git -C $env:C rev-parse --is-shallow-repository) -eq 'true') { $depth = @('--unshallow') }" ^
  "  Run-Git -C $env:C fetch -q --no-tags @depth $mirror ('refs/heads/' + $env:BRANCH);" ^
  "  if ($env:PAINT_BASE) { Run-Git -C $env:C fetch -q --no-tags --no-write-fetch-head $mirror ('+refs/heads/' + $env:PAINT_BASE + ':refs/ship-job/paint-base') }" ^
  "} finally { $lock.Dispose() }" >> "%RES%" 2>&1
if errorlevel 1 set "FAILED=mirror clone or fetch %BRANCH% (see Git output above)"
if defined FAILED goto collect
rem the checkout, in this job's own clone: stage 7 rewrites the tracked godot\assets\ships files here (manifest.json, the CODE
rem folder), and a plain checkout then refuses every rerun after the branch moved. So: list and save every tracked change
rem (clone_changes_before_checkout.txt and .patch); stop on a tracked change anywhere else (a hand fix in the clone); restore
rem only godot\assets\ships from the clone's own commit; then a plain checkout, never forced, that also refuses to overwrite
rem untracked or ignored files, so a local file the branch now tracks stops the job instead of being replaced (Artoo, PR 1179).
git -C "%C%" status --porcelain --untracked-files=no > "%O%\clone_changes_before_checkout.txt" 2> "%O%\log_clone_status.txt"
if errorlevel 1 set "FAILED=checkout: could not save the clone's change list or patch, nothing was reset"
if defined FAILED goto collect
git -C "%C%" diff --binary HEAD > "%O%\clone_changes_before_checkout.patch" 2>> "%O%\log_clone_status.txt"
if errorlevel 1 set "FAILED=checkout: could not save the clone's change list or patch, nothing was reset"
if defined FAILED goto collect
rem (1194, Artoo on PR 1254) a staged change is not in the patch above when the worktree matches HEAD, and the restores
rem below would erase it: stop before any reset.
git -C "%C%" diff --cached --quiet HEAD >> "%O%\log_clone_status.txt" 2>&1
if errorlevel 1 set "FAILED=checkout: the clone has staged changes (git diff --cached); nothing was reset"
if defined FAILED goto collect
rem (1194) tools\pc\tmo.bat is restored only when it is byte for byte the hand-off copy the last run made (its hash is in
rem .git\ship_job_tmo_handoff.txt); any other change to it is a hand edit and stops the job like one anywhere else.
set "TMO_GEN="
set "TMO_LEFT="
set "TMO_REC="
for /f %%H in ('git -C "%C%" hash-object -- tools/pc/tmo.bat 2^>nul') do set "TMO_LEFT=%%H"
if exist "%C%\.git\ship_job_tmo_handoff.txt" set /p TMO_REC=<"%C%\.git\ship_job_tmo_handoff.txt"
if defined TMO_LEFT if defined TMO_REC if /i "%TMO_LEFT%"=="%TMO_REC%" set "TMO_GEN=1"
set "TMO_EXCL=:(exclude)godot/assets/ships"
if defined TMO_GEN set "TMO_EXCL=:(exclude)tools/pc/tmo.bat"
rem git filters the list itself (findstr $ needs a CR and git writes LF only; Fable on PR 1190)
git -C "%C%" status --porcelain --untracked-files=no -- . ":(exclude)godot/assets/ships" ":(glob,exclude)godot/**/*.import" "%TMO_EXCL%" > "%O%\clone_changes_unexpected.txt" 2>> "%O%\log_clone_status.txt"
if errorlevel 1 set "FAILED=checkout: git status of the clone failed, nothing was reset"
if defined FAILED goto collect
for %%Z in ("%O%\clone_changes_unexpected.txt") do if %%~zZ GTR 0 set "FAILED=checkout: the clone has local changes outside godot\assets\ships, listed in clone_changes_unexpected.txt and saved in clone_changes_before_checkout.patch; nothing was reset"
if defined FAILED goto collect
for %%Z in ("%O%\clone_changes_before_checkout.txt") do if %%~zZ GTR 0 echo restoring the clone's install files listed in clone_changes_before_checkout.txt, saved first in clone_changes_before_checkout.patch >> "%RES%"
git -C "%C%" checkout -q HEAD -- godot/assets/ships >> "%RES%" 2>&1
if errorlevel 1 set "FAILED=checkout: could not restore godot\assets\ships in the clone"
if defined FAILED goto collect
rem the headless import rewrites tracked *.import files under godot (Nov 19: S9 run 2 stopped on 18 death atlas .import
rem files); they are saved in the patch above and restored from the clone's own commit like the install files
git -C "%C%" checkout -q HEAD -- ":(glob)godot/**/*.import" >> "%RES%" 2>&1
if errorlevel 1 set "FAILED=checkout: could not restore the godot *.import files in the clone"
if defined FAILED goto collect
rem (1194) the tools_live hand-off copy the last run made (below, checked above); restored like the install files
if defined TMO_GEN git -C "%C%" checkout -q HEAD -- tools/pc/tmo.bat >> "%RES%" 2>&1
if errorlevel 1 set "FAILED=checkout: could not restore tools\pc\tmo.bat in the clone"
if defined FAILED goto collect
git -C "%C%" checkout -q --no-overwrite-ignore -B shipjob FETCH_HEAD >> "%RES%" 2>&1
if errorlevel 1 set "FAILED=checkout %BRANCH%"
if defined FAILED goto collect
if not defined PAINT_BASE goto based
git -C "%C%" -c "user.name=%JOB_DIR%" -c "user.email=%JOB_DIR%@localhost" merge -q --no-edit --no-overwrite-ignore refs/ship-job/paint-base >> "%RES%" 2>&1
if errorlevel 1 set "FAILED=merge PAINT_BASE %PAINT_BASE%"
if defined FAILED git -C "%C%" merge --abort >> "%RES%" 2>&1
if defined FAILED goto collect
echo merged %PAINT_BASE%: the pictures of this run are a PREVIEW of that paint stack >> "%RES%"
:based
git -C "%C%" log -1 --format=commit=%%H >> "%RES%" 2>&1
rem (1194, Artoo on PR 1254) The recipe stages of a pinned commit run the clone's own tools\pc\tmo.bat. Copy the
rem tools_live tmo.bat over it, so every nested Blender and Godot step hands off to the canonical watchdog too. The next
rem run restores the file from the clone's commit before its checkout (above), only if its hash still matches the record.
if defined TMO_OK copy /y "%TMO%" "%C%\tools\pc\tmo.bat" > nul
if defined TMO_OK if errorlevel 1 set "FAILED=could not route the clone's tmo.bat to tools_live"
if defined FAILED goto collect
if defined TMO_OK git -C "%C%" hash-object -- tools/pc/tmo.bat > "%C%\.git\ship_job_tmo_handoff.txt" 2>> "%RES%"
if defined TMO_OK if errorlevel 1 set "FAILED=could not record the hash of the clone's tmo.bat hand-off copy"
if defined FAILED goto collect
if defined TMO_OK echo the clone's tools\pc\tmo.bat hands off to %TMO% >> "%RES%"

rem 3. import, then the stages, each in a fresh cmd so the variables the stages set end with them
cd /d "%C%"
set "TMO_STEP_OUT=%C%\godot\.godot"
set "TMO_STEP=ship import"
call "%TMO%" %SHIP_IMPORT_CAP% "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
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
set "TMO_STEP_OUT=%O%"
set "TMO_STEP=ship GPU readback"
call "%TMO%" %SHIP_CHECK_CAP% "%GD%" --path "%C%\godot" --script res://render/test/installed_ship_check.gd -- %CODE% > "%O%\log_readback_gpu.txt" 2>&1
set EL=%ERRORLEVEL%
echo gpu readback exit %EL% >> "%RES%"
if not "%EL%"=="0" set "CHECKFAIL=%CHECKFAIL% readback"
set "TMO_STEP=ship authored interiors"
call "%TMO%" %SHIP_CHECK_CAP% "%GD%" --headless --path "%C%\godot" --script res://fx/test/authored_interiors_check.gd -- "%GLB%" > "%O%\log_interiors.txt" 2>&1
set EL=%ERRORLEVEL%
echo authored interiors exit %EL% >> "%RES%"
if not "%EL%"=="0" set "CHECKFAIL=%CHECKFAIL% interiors"
set "TMO_STEP=ship death seam"
call "%TMO%" %SHIP_CHECK_CAP% "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%GLB%" > "%O%\log_death_seam.txt" 2>&1
set EL=%ERRORLEVEL%
echo death seam exit %EL% >> "%RES%"
if not "%EL%"=="0" set "CHECKFAIL=%CHECKFAIL% death_seam"
if defined CHECKFAIL set "FAILED=checks:%CHECKFAIL%"
set "TMO_STEP=ship shots"
if defined FAILED goto collect

rem 6. the shots, only now: everything above passed, so the installed glb is this run's and checked
call "%TMO%" %SHIP_SHOTS_CAP% "%GD%" --path "%C%\godot" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%O%\shots" --facs %FACS% --sets %SETS% --codes %CODE% > "%O%\log_shots.txt" 2>&1
set EL=%ERRORLEVEL%
echo shots exit %EL% >> "%RES%"
if not "%EL%"=="0" set "FAILED=shots"

rem 7. Copy the Board's deliverables. Robocopy exits 0 through 7 for successful copies.
:collect
if not exist "%RECIPE%" (
  echo collect: no recipe\%SHIP% folder >> "%RES%"
  if not defined FAILED set "FAILED=collect (no recipe\%SHIP% folder)"
  goto finish
)
robocopy "%RECIPE%" "%O%\recipe" *.txt *.json *.md *.jpg /S /XJ /R:1 /W:1 /XD sil "%RECIPE%\godot\proj" "%RECIPE%\export" > "%O%\log_collect.txt" 2>&1
if errorlevel 8 if not defined FAILED set "FAILED=collect (reports)"
for /d %%D in ("%RECIPE%\clay" "%RECIPE%\r" "%RECIPE%\close" "%RECIPE%\surface" "%RECIPE%\godot" "%RECIPE%\shots" "%RECIPE%\shots_*") do if exist "%%~fD\" (
  robocopy "%%~fD" "%O%\recipe\%%~nxD" *.png *.jpg *.jpeg *.gif /S /XJ /R:1 /W:1 /XD sil "%RECIPE%\godot\proj" >> "%O%\log_collect.txt" 2>&1
  if errorlevel 8 if not defined FAILED set "FAILED=collect (shots)"
)
if exist "%RECIPE%\export\%CODE%\" (
  robocopy "%RECIPE%\export\%CODE%" "%O%\recipe\export\%CODE%" /E /XJ /R:1 /W:1 /XD sil "%RECIPE%\export\%CODE%\godot\proj" /XF *.blend b0.npz >> "%O%\log_collect.txt" 2>&1
  if errorlevel 8 if not defined FAILED set "FAILED=collect (export)"
)
echo collect: see log_collect.txt >> "%RES%"
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
