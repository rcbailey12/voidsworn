@echo off
rem Ship recipe, stage 4: the faction parts kit. Builds the hull with the faction kit's parts at the sockets in ships\SHIP.json
rem (tools\blender\kits\FACTION\kit.py; shared plumbing in kits\shared), audits it (nothing floats, nothing crosses the build's own
rem break lines, no gun aimed backward or into the ship against its mount normal), proves the audit can fail (audit_selftest.py),
rem re-scores the outline overlap with the parts on, and renders clay close-ups for legacy ships.
rem Stops with FAILED (non-zero exit) when the build is missing, the audit lists any problem or crossing, or the self-test fails.
rem The outline overlap is printed and reported, not a pass bar (RULEBOOK 5.8).
call "%~dp0env.bat"
if not exist "%JOB%\build" mkdir "%JOB%\build"
setlocal
set "PC_GPU_MODE=none"
set "TMO_STEP=recipe 4 parts build"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_PARTS_CAP% "%B%" -b -P "%R%\%HULL%.py" -- "%JOB%\build" %CELL% > "%JOB%\log_build.txt" 2>&1
if errorlevel 1 (echo Stage 4 FAILED: the parts build exited %ERRORLEVEL%. See %JOB%\log_build.txt & goto bad)
findstr /L /c:"[209] {" "%JOB%\log_build.txt" > nul || (echo Stage 4 FAILED: the build did not write %JOB%\build\%CELL%.blend. See %JOB%\log_build.txt & goto bad)
rem issue 592: a ship built from a build sheet proves its contract first (the sheet's seams, mounts, turrets, engines, insides
rem and length reach the recipe unchanged but for units)
if "%SHEET%"=="" goto audit
set "TMO_STEP=recipe 4 sheet contract"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_CHECK_CAP% "%B%" -b -P "%RC%\sheet_contract_selftest.py" -- "%R209_SHIP%" "%JOB%\build" > "%JOB%\log_sheet_contract.txt" 2>&1
if errorlevel 1 (type "%JOB%\log_sheet_contract.txt" & echo Stage 4 FAILED: the build sheet contract lost or changed a datum. See %JOB%\log_sheet_contract.txt & goto bad)
:audit
set "TMO_STEP=recipe 4 parts audit"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_CHECK_CAP% "%B%" -b "%JOB%\build\%CELL%.blend" -P "%RC%\audit.py" -- "%JOB%\audit.json" > "%JOB%\log_audit.txt" 2>&1
set AUD=%errorlevel%
if not exist "%JOB%\audit.json" (echo Stage 4 FAILED: the audit did not run. See %JOB%\log_audit.txt & goto bad)
type "%JOB%\audit.json"
if not "%AUD%"=="0" (echo Stage 4 FAILED: the audit found problems ^(audit.json^). & goto bad)
set "TMO_STEP=recipe 4 audit self-test"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_CHECK_CAP% "%B%" -b "%JOB%\build\%CELL%.blend" -P "%RC%\audit_selftest.py" -- "%JOB%\audit_selftest" > "%JOB%\log_audit_selftest.txt" 2>&1
if errorlevel 1 (echo Stage 4 FAILED: the audit did not refuse a broken build. See %JOB%\log_audit_selftest.txt & goto bad)
set "TMO_STEP=recipe 4 parts silhouette"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_PARTS_CAP% "%B%" -b -P "%R%\sil_dump.py" -- "%JOB%\%CELL%.npz" build %HULL% %CELL% > "%JOB%\log_sildump.txt" 2>&1
if errorlevel 1 (echo Stage 4 FAILED: the parts silhouette exited %ERRORLEVEL%. See %JOB%\log_sildump.txt & goto bad)
findstr /L /c:"[sil] dumped" "%JOB%\log_sildump.txt" > nul || (echo Stage 4 FAILED: the outline dump failed. See %JOB%\log_sildump.txt & goto bad)
endlocal
set CAMJ=
for /f "usebackq delims=" %%L in (`""%BPY%" "%RC%\ship.py" %SHIP% get concept_camera"`) do set CAMJ=%%L
if "%CAMJ%"=="" (set CAMJ=%JOB%\concept_camera.json) else (set CAMJ=%REPO%\%CAMJ%)
if not exist "%JOB%\sil" mkdir "%JOB%\sil"
set "TMO_STEP=recipe 4 score parts outline"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_CHECK_CAP% "%BPY%" -u "%R%\silhouette4.py" score "%JOB%\concept.png" "%CAMJ%" "%JOB%\sil" %CELL%="%JOB%\%CELL%.npz" > "%JOB%\log_sil.txt" 2>&1
if errorlevel 1 (echo Stage 4 FAILED: the outline could not be scored. See %JOB%\log_sil.txt & goto bad)
"%BPY%" "%RC%\ship.py" %SHIP% gate "%JOB%\sil\silhouette_scores.json"
set GATE=%errorlevel%
rem Issue 363: the standing checks with the parts on: outline per third and inner edges, and the second camera (the game
rem battle camera at r 170) against the B0 shape reference.
set "TMO_STEP=recipe 4 check outline thirds"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_CHECK_CAP% "%BPY%" -u "%R%\outline_thirds.py" "%JOB%\concept.png" "%CAMJ%" "%JOB%\sil" %CELL%="%JOB%\%CELL%.npz" > "%JOB%\log_thirds4.txt" 2>&1
if errorlevel 1 (echo Stage 4 FAILED: the outline per third and inner edge check did not run. See %JOB%\log_thirds4.txt & goto bad)
set "TMO_STEP=recipe 4 check outline record"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_CHECK_CAP% "%BPY%" -u "%RC%\standing.py" outline --ship "%R209_SHIP%" --job "%JOB%" > "%JOB%\log_standing4.txt" 2>&1
if errorlevel 1 (type "%JOB%\log_standing4.txt" & echo Stage 4 FAILED: the standing outline record is incomplete. See %JOB%\log_standing4.txt & goto bad)
type "%JOB%\log_standing4.txt"
set "TMO_STEP=recipe 4 score second-camera outline"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_CHECK_CAP% "%BPY%" -u "%R%\outline_battle.py" "%JOB%\sil" ref="%JOB%\b0.npz" %CELL%="%JOB%\%CELL%.npz" > "%JOB%\log_battle.txt" 2>&1
if errorlevel 1 (echo Stage 4 FAILED: the second-camera outline score did not run. See %JOB%\log_battle.txt & goto bad)
set "TMO_STEP=recipe 4 check second-camera record"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_CHECK_CAP% "%BPY%" -u "%RC%\standing.py" battle --ship "%R209_SHIP%" --job "%JOB%" > "%JOB%\log_standing_battle.txt" 2>&1
if errorlevel 1 (type "%JOB%\log_standing_battle.txt" & echo Stage 4 FAILED: the second-camera outline score is incomplete. See %JOB%\log_standing_battle.txt & goto bad)
type "%JOB%\log_standing_battle.txt"
if defined SHEET goto skip_clay
set "TMO_STEP=recipe 4 clay renders"
call "%REPO%\tools\pc\tmo.bat" %RECIPE_PARTS_CAP% "%B%" -b "%JOB%\build\%CELL%.blend" -P "%R%\close6.py" -- "%JOB%\clay" %CELL% 32 > "%JOB%\log_clay.txt" 2>&1
if errorlevel 1 (echo Stage 4 FAILED: the clay renders exited %ERRORLEVEL%. See %JOB%\log_clay.txt & goto bad)
echo Close-ups in %JOB%\clay
goto clay_done
:skip_clay
echo Stage 4: skipped C15s clay close-ups for sheet ship %SHIP%. > "%JOB%\log_clay.txt"
type "%JOB%\log_clay.txt"
:clay_done
if not "%GATE%"=="0" (echo Stage 4 FAILED: the outline score could not be read. & goto bad)
echo Stage 4 done: audit PASS, outline overlap reported above (not a pass bar, RULEBOOK 5.8)
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 0
:bad
if "%RECIPE_NOPAUSE%"=="" pause
exit /b 1
