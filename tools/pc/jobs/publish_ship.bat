@echo off
rem Issue 1311: publish one accepted ship build into the shared game build (build\godot), which every capture job and the
rem playtest exe read. ship_job.bat installs a new build only into its own job clone; nothing reached build\godot until this.
rem Run it only after Ryan says yes to the ship's pictures (the Board queues it then; docs/playbooks/ships.md).
rem
rem   publish_ship.bat JOB_DIR CODE [GLB_SHA]
rem     JOB_DIR  the ship job's folder under Downloads\voidsworn_test (opus1156)
rem     CODE     the hull code it built (V14_23)
rem     GLB_SHA  optional: the start of the glb's sha256 the Board expects (01b16b32); any other glb is refused
rem
rem What it does, in order. Any failure stops it; result.txt ends "all done PASS" or "all done FAILED: <step>".
rem   1. refuses unless JOB_DIR\out\result.txt is a ship_job result for CODE that ends "done PASS" / "all done" and has its
rem      commit= line, and every file the job checked (the clone's installed godot\assets\ships\CODE, Godot's own .import
rem      and .uid files aside) is byte for byte in the job's collected export (out\recipe\export\CODE)
rem   2. copies that export into its own publish folder, so the job's evidence is never touched
rem   3. never deletes: copies the old assets\ships\CODE folder, its gen scenes and both manifests to
rem      build\godot\_replaced\CODE_<stamp>\ (a .gdignore keeps Godot out) and writes UNDO_CODE.bat there, which puts them back
rem   4. manifest_merge.py --install from the job's own clone (the tools that built it): the export checks, the install
rem      with its own rollback, the ship's cache rebuilt and the installed readback
rem   5. render/build_assets.gd --ships-only over build\godot, then the installed readback again on the published copy
rem   6. in-game shots of CODE from build\godot (battle and close), so the picture names the hull code
rem Every step runs through tools_live's tmo.bat (fail closed if it is missing). Writes only build\godot (the ship, its
rem cache, the two manifests, _replaced\) and Downloads\voidsworn_test\publish\CODE_<stamp>\.
setlocal EnableExtensions
set "V=%USERPROFILE%\Downloads\voidsworn_test"
set "JOB_DIR=%~1"
set "CODE=%~2"
set "WANT=%~3"
if "%CODE%"=="" (
  echo usage: publish_ship.bat JOB_DIR CODE [GLB_SHA]
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
echo start publish %JOB_DIR% %CODE% %DATE% %TIME% > "%RES%"
set "FAILED="
set "J=%V%\%JOB_DIR%"
set "JRES=%J%\out\result.txt"
set "EXP=%J%\out\recipe\export\%CODE%"
set "INST=%J%\repo\godot\assets\ships\%CODE%"
set "TOOLS=%J%\repo\tools\recipe"
set "GAME=%V%\build\godot"
set "GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "BPY=%V%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe"
set "B=%GAME%\_replaced\%CODE%_%STAMP%"

rem the canonical watchdog only
set "TLV="
if exist "%V%\tools_live\current.txt" set /p TLV=<"%V%\tools_live\current.txt"
if not defined TLV set "FAILED=tools_live\current.txt is missing or empty"
if defined FAILED goto finish
set "TMO=%V%\tools_live\%TLV%\pc\tmo.bat"
if not exist "%TMO%" set "FAILED=no watchdog at %TMO%"
if defined FAILED goto finish
echo watchdog %TMO% >> "%RES%"
if not exist "%GAME%\project.godot" set "FAILED=no game project at %GAME%"
if not exist "%GD%" set "FAILED=no Godot at %GD%"
if not exist "%BPY%" set "FAILED=no Blender python at %BPY%"
if defined FAILED goto finish

rem 1. the job must have passed, for this code, and what it checked must be what it collected
if not exist "%JRES%" set "FAILED=refused: no %JRES%"
if defined FAILED goto finish
set "SHIP="
set "JCODE="
for /f "usebackq tokens=1,2,3" %%a in ("%JRES%") do if not defined SHIP if "%%a"=="start" (set "SHIP=%%b"& set "JCODE=%%c")
if /i not "%JCODE%"=="%CODE%" set "FAILED=refused: %JOB_DIR% built %JCODE%, not %CODE%"
if defined FAILED goto finish
findstr /b /c:"done PASS" "%JRES%" > nul || set "FAILED=refused: %JOB_DIR% result.txt has no done PASS line"
findstr /b /c:"done FAILED" "%JRES%" > nul && set "FAILED=refused: %JOB_DIR% result.txt has a done FAILED line"
findstr /b /c:"commit=" "%JRES%" > nul || set "FAILED=refused: %JOB_DIR% result.txt has no commit= line (pin unknown)"
if defined FAILED goto finish
set "LAST="
for /f "usebackq delims=" %%L in ("%JRES%") do set "LAST=%%L"
rem ship_job lines end in a space
if not "%LAST:~0,8%"=="all done" set "FAILED=refused: %JOB_DIR% result.txt does not end in all done"
if defined FAILED goto finish
for /f "usebackq delims=" %%L in (`findstr /b /c:"commit=" "%JRES%"`) do echo job %JOB_DIR% ship %SHIP% %%L >> "%RES%"
if not exist "%TOOLS%\manifest_merge.py" set "FAILED=refused: no %TOOLS%\manifest_merge.py in the job's clone"
if not exist "%J%\repo\tools\recipe\ships\%SHIP%.json" set "FAILED=refused: no ships\%SHIP%.json in the job's clone"
if defined FAILED goto finish
powershell -NoProfile -Command ^
  "$ErrorActionPreference = 'Stop'; $inst = $env:INST; $exp = $env:EXP; $code = $env:CODE;" ^
  "if (-not (Test-Path -LiteralPath (Join-Path $inst ($code + '.glb')))) { throw ('the job clone has no installed ' + $code + '.glb') }" ^
  "$n = 0; foreach ($f in Get-ChildItem -LiteralPath $inst -File | Where-Object { $_.Extension -notin '.import', '.uid' }) {" ^
  "  $o = Join-Path $exp $f.Name; if (-not (Test-Path -LiteralPath $o)) { throw ($f.Name + ' was checked but is not in the collected export') }" ^
  "  if ((Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $o -Algorithm SHA256).Hash) { throw ($f.Name + ' differs from what the job checked') }; $n++ }" ^
  "$g = (Get-FileHash -LiteralPath (Join-Path $exp ($code + '.glb')) -Algorithm SHA256).Hash.ToLower();" ^
  "if ($env:WANT -and -not $g.StartsWith($env:WANT.ToLower())) { throw ('glb sha256 ' + $g + ' is not the expected ' + $env:WANT) }" ^
  "Write-Output ('identity: ' + $n + ' checked files match the export, glb sha256 ' + $g)" >> "%RES%" 2>&1
if errorlevel 1 set "FAILED=refused: the export is not what the job checked (see above)"
if defined FAILED goto finish

rem 2. our own copy of the export
robocopy "%EXP%" "%P%\export\%CODE%" /E /XJ /R:1 /W:1 > "%P%\log_copy.txt" 2>&1
if errorlevel 8 set "FAILED=could not copy the export"
if defined FAILED goto finish
fc /b "%EXP%\%CODE%.glb" "%P%\export\%CODE%\%CODE%.glb" > nul || set "FAILED=the export copy differs"
if defined FAILED goto finish

rem 3. the old files aside, and the undo
if not exist "%GAME%\_replaced" mkdir "%GAME%\_replaced"
if not exist "%GAME%\_replaced\.gdignore" type nul > "%GAME%\_replaced\.gdignore"
mkdir "%B%" || set "FAILED=could not make %B%"
if defined FAILED goto finish
for %%D in ("assets\ships" "gen\ships" "gen\damage" "gen\wreck") do mkdir "%B%\%%~D"
set "HAD_SHIP="
if exist "%GAME%\assets\ships\%CODE%\" set "HAD_SHIP=1"
if defined HAD_SHIP robocopy "%GAME%\assets\ships\%CODE%" "%B%\ship" /E /XJ /R:1 /W:1 > "%P%\log_backup.txt" 2>&1
if defined HAD_SHIP if errorlevel 8 set "FAILED=could not copy the old ship folder aside"
if defined FAILED goto finish
for %%F in ("assets\ships\manifest.json" "gen\manifest.json" "gen\ships\%CODE%.scn" "gen\damage\%CODE%_damage.scn" "gen\wreck\%CODE%_wreck.scn") do if exist "%GAME%\%%~F" (
  copy /y "%GAME%\%%~F" "%B%\%%~F" > nul || set "FAILED=could not copy %%~F aside"
)
if defined FAILED goto finish
call :undo > "%B%\UNDO_%CODE%.bat"
copy /y "%B%\UNDO_%CODE%.bat" "%P%\UNDO_%CODE%.bat" > nul
echo old files kept in %B% (HAD_SHIP=%HAD_SHIP%), undo: %B%\UNDO_%CODE%.bat >> "%RES%"

rem 4. the install, from the job's own tools
set RECIPE_NOPAUSE=1
set "TMO_STEP_OUT=%P%"
set "TMO_STEP=publish install %CODE%"
call "%TMO%" 3600 "%BPY%" -B "%TOOLS%\manifest_merge.py" --install "%P%\export\%CODE%" "%GAME%" %CODE% "%GD%" "%P%" "%J%\repo\tools\recipe\ships\%SHIP%.json" > "%P%\log_install.txt" 2>&1
set EL=%ERRORLEVEL%
echo install exit %EL% >> "%RES%"
findstr /c:"INSTALL READBACK PASS" "%P%\log_install.txt" >> "%RES%"
if not "%EL%"=="0" set "FAILED=install (log_install.txt; manifest_merge rolled back, the old files are also in %B%)"
if defined FAILED goto finish

rem 5. the whole ship cache, then the readback on the published copy
set "TMO_STEP=publish ships cache"
call "%TMO%" 2400 "%GD%" --headless --path "%GAME%" --script res://render/build_assets.gd -- --ships-only > "%P%\log_ships_cache.txt" 2>&1
set EL=%ERRORLEVEL%
echo ships cache exit %EL% >> "%RES%"
if not "%EL%"=="0" set "FAILED=ships cache (UNDO_%CODE%.bat puts the old ship back)"
if defined FAILED goto finish
findstr /c:"[assets] ships refreshed:" "%P%\log_ships_cache.txt" >> "%RES%" || set "FAILED=ships cache printed no refreshed line"
if defined FAILED goto finish
set "TMO_STEP=publish readback %CODE%"
call "%TMO%" 600 "%GD%" --path "%GAME%" --script res://render/test/installed_ship_check.gd -- %CODE% > "%P%\log_readback.txt" 2>&1
set EL=%ERRORLEVEL%
echo readback exit %EL% >> "%RES%"
findstr /c:"INSTALL READBACK" "%P%\log_readback.txt" >> "%RES%"
if not "%EL%"=="0" set "FAILED=readback on build\godot (UNDO_%CODE%.bat puts the old ship back)"
if defined FAILED goto finish

rem 6. the in-game picture, from the published copy
set "FACS="
for /f "delims=_" %%F in ("%SHIP%") do set "FACS=%%F"
set "TMO_STEP=publish shots %CODE%"
call "%TMO%" 600 "%GD%" --path "%GAME%" --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out "%P%\shots" --facs %FACS% --sets battle,close --codes %CODE% > "%P%\log_shots.txt" 2>&1
set EL=%ERRORLEVEL%
echo shots exit %EL% >> "%RES%"
if not "%EL%"=="0" set "FAILED=shots (the ship is published and passed its readback; only the picture failed)"

:finish
if defined FAILED goto failed
echo published %CODE% from %JOB_DIR% into %GAME% >> "%RES%"
echo all done PASS %DATE% %TIME% >> "%RES%"
exit /b 0
:failed
echo all done FAILED: %FAILED% %DATE% %TIME% >> "%RES%"
exit /b 1

:undo
rem writes UNDO_CODE.bat: the published ship and its scenes moved to _replaced\CODE_<stamp>_undone_<time>, the kept copies put
rem back, the ship cache rebuilt. Nothing is deleted. The two manifests come back as they were before this publish.
echo @echo off
echo rem Issue 1311: put %CODE% in build\godot back as it was before the publish of %STAMP% from %JOB_DIR%. Deletes nothing.
echo setlocal EnableExtensions
echo set "U=%GAME%\_replaced\%CODE%_%STAMP%_undone_%%RANDOM%%"
echo mkdir "%%U%%" ^|^| exit /b 1
echo if exist "%GAME%\assets\ships\%CODE%\" move "%GAME%\assets\ships\%CODE%" "%%U%%\ship" ^|^| exit /b 1
if defined HAD_SHIP echo robocopy "%B%\ship" "%GAME%\assets\ships\%CODE%" /E /XJ /R:1 /W:1 ^> nul
if defined HAD_SHIP echo if errorlevel 8 exit /b 1
for %%F in ("gen\ships\%CODE%.scn" "gen\damage\%CODE%_damage.scn" "gen\wreck\%CODE%_wreck.scn") do echo if exist "%GAME%\%%~F" move "%GAME%\%%~F" "%%U%%\%%~nxF" ^> nul
for %%F in ("assets\ships\manifest.json" "gen\manifest.json") do echo copy /y "%GAME%\%%~F" "%%U%%\%%~nxF.published" ^> nul
for %%F in ("assets\ships\manifest.json" "gen\manifest.json" "gen\ships\%CODE%.scn" "gen\damage\%CODE%_damage.scn" "gen\wreck\%CODE%_wreck.scn") do if exist "%B%\%%~F" echo copy /y "%B%\%%~F" "%GAME%\%%~F" ^> nul
echo call "%TMO%" 2400 "%GD%" --headless --path "%GAME%" --script res://render/build_assets.gd -- --ships-only ^> "%%U%%\log_ships_cache.txt" 2^>^&1
echo echo undo of %CODE% done, published files kept in %%U%%
exit /b 0
