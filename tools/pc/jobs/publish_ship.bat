@echo off
rem Issue 1311: publish one accepted ship build into the shared game build (build\godot), which every capture job and the
rem playtest exe read. ship_job.bat installs a new build only into its own job clone; nothing reached build\godot until this.
rem Run it only after Ryan says yes to the ship's pictures (the Board queues it then; docs/playbooks/ships.md rule 15).
rem
rem   publish_ship.bat JOB_DIR CODE COMMIT GLB_SHA
rem     JOB_DIR  the ship job's folder under Downloads\voidsworn_test (opus1156)
rem     CODE     the hull code it built (V14_23)
rem     COMMIT   the full commit the job built, from its receipt's commit= line; it must match exactly
rem     GLB_SHA  the full sha256 of CODE.glb, from the job's export\CODE\CODE_export.json; it must match exactly
rem
rem What it does, in order. Any failure stops it; result.txt ends "all done PASS" or "all done FAILED: <step>".
rem   1. publish_ship.py receipt: refuses unless JOB_DIR\out\result.txt is a passed ship_job receipt for CODE at exactly
rem      COMMIT (its tail "all done", or "all done" then "pin ok COMMIT"), the collected export holds every listed file with
rem      its listed sha256, the glb is exactly GLB_SHA, and every file the job checked is byte for byte in that export
rem   2. copies that export into its own publish folder, so the job's evidence is never touched
rem   3. publish_ship.py backup: never deletes; copies the old ship folder and its cache scenes to
rem      build\godot\_replaced\CODE_<stamp>\ (a .gdignore keeps Godot out), records CODE's own manifest rows, and writes
rem      UNDO_CODE.bat there
rem   4. manifest_merge.py --install from the job's own clone (the tools that built it): the export checks, the install with
rem      its own rollback, the ship's cache rebuilt and the installed readback; then publish_ship.py seal (below), so the
rem      undo works from here on. If the install fails, publish_ship.py restore puts back every kept file (the damage and wreck
rem      scenes too, which manifest_merge's rollback leaves rewritten) and the result names anything that still differs
rem   5. render/build_assets.gd --ships-only over build\godot, under the install lock (publish_ship.py locked), then the
rem      installed readback again on the published copy
rem   6. publish_ship.py seal: records what is now live for CODE; the undo refuses once that changes (sealed again here
rem      after the cache rebuild)
rem   7. in-game shots of CODE from build\godot (battle and close), so the picture names the hull code
rem Every step runs through tools_live's tmo.bat, and publish_ship.py is tools_live's own copy (fail closed if either is
rem missing). Writes only build\godot (the ship, its cache, the two manifests, _replaced\) and voidsworn_test\publish\.
rem   8. after a PASS, the job's own clone JOB_DIR\repo goes (issue 1497, RULEBOOK 3.3), through tools_live's head
rem      (opus_job_head.ps1 droprepo); nothing else is deleted
setlocal EnableExtensions
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "JOB_DIR=%~1"
set "CODE=%~2"
set "COMMIT=%~3"
set "GLB_SHA=%~4"
if "%GLB_SHA%"=="" (
  echo usage: publish_ship.bat JOB_DIR CODE COMMIT GLB_SHA
  exit /b 2
)
echo %CODE%| findstr /r /x "[A-Za-z0-9_][A-Za-z0-9_]*" > nul
if errorlevel 1 (
  echo publish_ship.bat: %CODE% is not a hull code
  exit /b 2
)
set "STAMP="
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd_HHmmss')"`) do set "STAMP=%%T"
if not defined STAMP exit /b 1
set "P=%V%\publish\%CODE%_%STAMP%"
if exist "%P%" exit /b 1
mkdir "%P%" || exit /b 1
set "RES=%P%\result.txt"
echo start publish %JOB_DIR% %CODE% %COMMIT% %GLB_SHA% %DATE% %TIME% > "%RES%"
set "FAILED="
rem Ryan's real game options are never touched (Fable, PR 1312; the 1078 pattern): his battle_opts.json and board_look.cfg
rem are hashed now and at the end, into result.txt, and every program this job starts (the Godot cache build under python
rem too) sees APPDATA and LOCALAPPDATA in the publish folder's throwaway profile. A change fails the job.
set "REALU=%APPDATA%\Godot\app_userdata\Voidsworn"
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%P%\real_opts_before.txt" 2>&1 || set "FAILED=could not hash Ryan's real options before the publish; nothing was started"
if defined FAILED goto finish
mkdir "%P%\profile\Roaming" "%P%\profile\Local" || set "FAILED=could not make the throwaway profile; nothing was started"
if defined FAILED goto finish
set "APPDATA=%P%\profile\Roaming"
set "LOCALAPPDATA=%P%\profile\Local"
echo profile guard APPDATA=%APPDATA% >> "%RES%"
set "J=%V%\%JOB_DIR%"
set "GAME=%V%\build\godot"
set "GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "BPY=%V%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe"
set "B=%GAME%\_replaced\%CODE%_%STAMP%"

rem the canonical watchdog and publish tool only
set "TLV="
if exist "%V%\tools_live\current.txt" set /p TLV=<"%V%\tools_live\current.txt"
if not defined TLV set "FAILED=tools_live\current.txt is missing or empty"
if defined FAILED goto finish
set "TMO=%V%\tools_live\%TLV%\pc\tmo.bat"
set "PUB=%V%\tools_live\%TLV%\recipe\publish_ship.py"
if not exist "%TMO%" set "FAILED=no watchdog at %TMO%"
if not exist "%PUB%" set "FAILED=no %PUB%: refresh tools_live from a main that has issue 1311"
if not exist "%GAME%\project.godot" set "FAILED=no game project at %GAME%"
if not exist "%GD%" set "FAILED=no Godot at %GD%"
if not exist "%BPY%" set "FAILED=no Blender python at %BPY%"
if defined FAILED goto finish
echo watchdog %TMO% >> "%RES%"
echo publish tool %PUB% >> "%RES%"
set RECIPE_NOPAUSE=1
set "TMO_STEP_OUT=%P%"

rem 1. the receipt, the exact commit, the exact glb, what the job checked
set "TMO_STEP=publish receipt %CODE%"
call "%TMO%" 600 "%BPY%" -B "%PUB%" receipt "%J%" %CODE% %COMMIT% %GLB_SHA% "%P%\receipt.json" > "%P%\log_receipt.txt" 2>&1
set EL=%ERRORLEVEL%
type "%P%\log_receipt.txt" >> "%RES%"
if not "%EL%"=="0" set "FAILED=refused: the receipt or export does not match (log_receipt.txt)"
if defined FAILED goto finish
set "SHIP="
for /f "usebackq tokens=1,* delims==" %%a in ("%P%\log_receipt.txt") do if "%%a"=="SHIP" set "SHIP=%%b"
if not defined SHIP set "FAILED=the receipt check named no ship"
if defined FAILED goto finish
if not exist "%J%\repo\tools\recipe\manifest_merge.py" set "FAILED=refused: no manifest_merge.py in the job's clone"
if not exist "%J%\repo\tools\recipe\ships\%SHIP%.json" set "FAILED=refused: no ships\%SHIP%.json in the job's clone"
if defined FAILED goto finish

rem 2. our own copy of the export
robocopy "%J%\out\recipe\export\%CODE%" "%P%\export\%CODE%" /E /XJ /R:1 /W:1 > "%P%\log_copy.txt" 2>&1
if errorlevel 8 set "FAILED=could not copy the export"
if defined FAILED goto finish
fc /b "%J%\out\recipe\export\%CODE%\%CODE%.glb" "%P%\export\%CODE%\%CODE%.glb" > nul || set "FAILED=the export copy differs"
if defined FAILED goto finish

rem 3. the old files aside, and the undo
if not exist "%GAME%\_replaced" mkdir "%GAME%\_replaced"
if not exist "%GAME%\_replaced\.gdignore" type nul > "%GAME%\_replaced\.gdignore"
set "TMO_STEP=publish backup %CODE%"
call "%TMO%" 600 "%BPY%" -B "%PUB%" backup "%GAME%" %CODE% "%B%" > "%P%\log_backup.txt" 2>&1
set EL=%ERRORLEVEL%
type "%P%\log_backup.txt" >> "%RES%"
if not "%EL%"=="0" set "FAILED=could not keep the old files (log_backup.txt); nothing was installed"
if defined FAILED goto finish
rem the undo carries its own copy of the tool (tools_live versions rotate out after a day)
mkdir "%B%\tool" || set "FAILED=could not make %B%\tool"
if defined FAILED goto finish
copy /y "%PUB%" "%B%\tool\publish_ship.py" > nul || set "FAILED=could not keep a copy of publish_ship.py"
if defined FAILED goto finish
copy /y "%V%\tools_live\%TLV%\recipe\manifest_merge.py" "%B%\tool\manifest_merge.py" > nul || set "FAILED=could not keep a copy of manifest_merge.py"
if defined FAILED goto finish
call :undo > "%B%\UNDO_%CODE%.bat"
findstr /x /c:"exit /b 1" "%B%\UNDO_%CODE%.bat" > nul || set "FAILED=could not write %B%\UNDO_%CODE%.bat; nothing was installed"
if defined FAILED goto finish
copy /y "%B%\UNDO_%CODE%.bat" "%P%\UNDO_%CODE%.bat" > nul
echo undo: %B%\UNDO_%CODE%.bat (after a failed install manifest_merge has already rolled back; the undo is for a live publish) >> "%RES%"

rem 4. the install, from the job's own tools
set "TMO_STEP=publish install %CODE%"
call "%TMO%" 3600 "%BPY%" -B "%J%\repo\tools\recipe\manifest_merge.py" --install "%P%\export\%CODE%" "%GAME%" %CODE% "%GD%" "%P%" "%J%\repo\tools\recipe\ships\%SHIP%.json" > "%P%\log_install.txt" 2>&1
set EL=%ERRORLEVEL%
echo install exit %EL% >> "%RES%"
findstr /c:"INSTALL READBACK PASS" "%P%\log_install.txt" >> "%RES%"
if not "%EL%"=="0" goto install_failed
set "TMO_STEP=publish seal %CODE%"
call "%TMO%" 600 "%BPY%" -B "%PUB%" seal "%GAME%" %CODE% "%B%" > "%P%\log_seal_install.txt" 2>&1
set EL=%ERRORLEVEL%
type "%P%\log_seal_install.txt" >> "%RES%"
if not "%EL%"=="0" set "FAILED=seal after the install (log_seal_install.txt; the new ship is live, the old files are in %B%)"
if defined FAILED goto finish

rem 5. the whole ship cache, then the readback on the published copy
set "TMO_STEP=publish ships cache"
call "%TMO%" 2400 "%BPY%" -B "%PUB%" locked "%GAME%" "%GD%" --headless --path "%GAME%" --script res://render/build_assets.gd -- --ships-only > "%P%\log_ships_cache.txt" 2>&1
set EL=%ERRORLEVEL%
echo ships cache exit %EL% >> "%RES%"
if not "%EL%"=="0" set "FAILED=ships cache (log_ships_cache.txt)"
if defined FAILED goto finish
findstr /c:"[assets] ships refreshed:" "%P%\log_ships_cache.txt" >> "%RES%" || set "FAILED=ships cache printed no refreshed line"
if defined FAILED goto finish
set "TMO_STEP=publish readback %CODE%"
call "%TMO%" 600 "%GD%" --path "%GAME%" --script res://render/test/installed_ship_check.gd -- %CODE% > "%P%\log_readback.txt" 2>&1
set EL=%ERRORLEVEL%
echo readback exit %EL% >> "%RES%"
findstr /c:"INSTALL READBACK" "%P%\log_readback.txt" >> "%RES%"
if not "%EL%"=="0" set "FAILED=readback on build\godot (log_readback.txt)"
if defined FAILED goto finish

rem 6. the seal again, after the cache: the undo refuses once CODE changes after this
set "TMO_STEP=publish seal %CODE%"
call "%TMO%" 600 "%BPY%" -B "%PUB%" seal "%GAME%" %CODE% "%B%" > "%P%\log_seal.txt" 2>&1
set EL=%ERRORLEVEL%
type "%P%\log_seal.txt" >> "%RES%"
if not "%EL%"=="0" set "FAILED=seal (log_seal.txt)"
if defined FAILED goto finish

rem 7. the in-game picture, from the published copy
set "FACS="
for /f "delims=_" %%F in ("%SHIP%") do set "FACS=%%F"
rem build\godot has no tools folder beside it, so the stamp tool is tools_live's own copy, run by the Blender python
set "PICTURE_STAMP_TOOL=%V%\tools_live\%TLV%\picture_provenance.py"
set "PICTURE_PYTHON=%BPY%"
rem build\ is not a git checkout; the picture names the commit the ship was built at, from the job's own clone
set "PICTURE_SOURCE_REPO=%J%\repo"
if not exist "%PICTURE_STAMP_TOOL%" set "FAILED=no %PICTURE_STAMP_TOOL% (the ship is published, read back and sealed; only the picture could not run)"
if defined FAILED goto finish
set "TMO_STEP=publish shots %CODE%"
call "%TMO%" 600 "%GD%" --path "%GAME%" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%P%\shots" --facs %FACS% --sets battle,close --codes %CODE% > "%P%\log_shots.txt" 2>&1
set EL=%ERRORLEVEL%
echo shots exit %EL% >> "%RES%"
if not "%EL%"=="0" set "FAILED=shots (the ship is published, read back and sealed; only the picture failed)"

goto finish

rem a failed install: manifest_merge rolled back the ship, its scene and both manifests, but the cache refresh may have
rem rewritten the damage and wreck scenes in place (Fable, PR 1312); restore puts every kept file back and says what it did
:install_failed
set "TMO_STEP=publish restore %CODE%"
call "%TMO%" 600 "%BPY%" -B "%PUB%" restore "%GAME%" %CODE% "%B%" > "%P%\log_restore.txt" 2>&1
set EL=%ERRORLEVEL%
type "%P%\log_restore.txt" >> "%RES%"
if "%EL%"=="0" set "FAILED=install (log_install.txt); %CODE% is back exactly as before the publish (log_restore.txt)"
if not "%EL%"=="0" set "FAILED=install (log_install.txt) AND the restore (log_restore.txt names what still differs; the kept files are in %B%)"

:finish
rem Ryan's real options again, compared with the start (REALU was read before APPDATA was redirected)
if not exist "%P%\real_opts_before.txt" goto ending
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%P%\real_opts_after.txt" 2>&1
echo Ryan's real options before: >> "%RES%"
type "%P%\real_opts_before.txt" >> "%RES%"
echo Ryan's real options after: >> "%RES%"
type "%P%\real_opts_after.txt" >> "%RES%"
fc /b "%P%\real_opts_before.txt" "%P%\real_opts_after.txt" > nul && echo Ryan's real options unchanged ^(battle_opts.json, board_look.cfg^) >> "%RES%"
set "OPTSBAD="
fc /b "%P%\real_opts_before.txt" "%P%\real_opts_after.txt" > nul || set "OPTSBAD=Ryan's real options changed during the publish (or could not be hashed), see real_opts_before.txt and real_opts_after.txt"
if defined OPTSBAD if defined FAILED set "FAILED=%FAILED%; %OPTSBAD%"
if defined OPTSBAD if not defined FAILED set "FAILED=%OPTSBAD%"
:ending
if defined FAILED goto failed
rem (1497) The ship is live, sealed and pictured, so the job's own clone (14 to 16 GB) has done its work: tools_live's head
rem removes JOB_DIR\repo only when HEAD is COMMIT, every local commit is in the shared mirror and its files are rebuildable
rem or saved first into JOB_DIR\out\checkout_leftovers_repo. The job's out folder, this publish folder and the undo stay.
rem A refusal is logged and never fails the publish. A later publish from the same job folder needs a new ship_job run.
set "OJH=%V%\tools_live\%TLV%\pc\jobs\opus_job_head.ps1"
if exist "%OJH%" powershell -NoProfile -ExecutionPolicy Bypass -File "%OJH%" droprepo "%J%" %COMMIT% %CODE% >> "%RES%" 2>&1
if not exist "%OJH%" echo ship clone kept: no opus_job_head.ps1 in tools_live >> "%RES%"
echo published %CODE% from %JOB_DIR% at %COMMIT% into %GAME% >> "%RES%"
echo all done PASS %DATE% %TIME% >> "%RES%"
exit /b 0
:failed
echo all done FAILED: %FAILED% %DATE% %TIME% >> "%RES%"
exit /b 1

:undo
rem writes UNDO_CODE.bat. publish_ship.py undo, under the install lock, refuses if CODE changed since the seal, then moves
rem the published files aside, puts the kept ones back and restores only CODE's manifest rows; then the cache rebuild. It
rem prints "undo of CODE PASS" only when every step passed, and "undo of CODE FAILED: <step>" otherwise. Nothing is deleted.
echo @echo off
echo rem Issue 1311: put %CODE% in build\godot back as it was before the publish of %STAMP% from %JOB_DIR%. Deletes nothing.
echo setlocal EnableExtensions
echo if not exist "%B%\undo_profile\Roaming" mkdir "%B%\undo_profile\Roaming" "%B%\undo_profile\Local"
echo set "APPDATA=%B%\undo_profile\Roaming"
echo set "LOCALAPPDATA=%B%\undo_profile\Local"
echo set "U=%B%\undo_%%RANDOM%%.txt"
echo set "TLV="
echo if exist "%V%\tools_live\current.txt" set /p TLV=^<"%V%\tools_live\current.txt"
echo set "TMO=%V%\tools_live\%%TLV%%\pc\tmo.bat"
echo if not exist "%%TMO%%" echo no watchdog at %%TMO%% ^> "%%U%%"
echo if not exist "%%TMO%%" goto failed
echo call "%%TMO%%" 600 "%BPY%" -B "%B%\tool\publish_ship.py" undo "%GAME%" %CODE% "%B%" ^> "%%U%%" 2^>^&1
echo if errorlevel 1 goto failed
echo call "%%TMO%%" 2400 "%BPY%" -B "%B%\tool\publish_ship.py" locked "%GAME%" "%GD%" --headless --path "%GAME%" --script res://render/build_assets.gd -- --ships-only ^>^> "%%U%%" 2^>^&1
echo if errorlevel 1 goto failed
echo echo undo of %CODE% PASS ^>^> "%%U%%"
echo echo undo of %CODE% PASS, log in %%U%%
echo exit /b 0
echo :failed
echo echo undo of %CODE% FAILED, see %%U%% ^>^> "%%U%%"
echo echo undo of %CODE% FAILED, see %%U%%
echo exit /b 1
exit /b 0
