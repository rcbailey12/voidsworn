@echo off
rem Issue 1078: the shield failure looks (today's, energy shear, clean collapse) on the installed ships, for Ryan to pick.
rem   shield_looks_1078.bat [REF]     REF defaults to origin/opus/issue-1078
rem Writes S1078_HOME (default Downloads\voidsworn_test\opus1078): work\<commit>\ (stills, clip frames) and out\ (the sheets (one per subject, shield shape and camera), clip
rem an mp4 per story when an ffmpeg is found, the logs and json), then the cost pass with the GPU to itself (R293: PC_GPU_MODE=solo,
rem every shielded ship failing in the same frame, GPU time per look). out\result.txt logs each step and ends "all done".
rem Writes only under S1078_HOME. Nothing is deleted.
rem Optional settings: S1078_SHIPS (a godot folder with the installed hulls, default build\godot), S1078_SKIP_LOOK=1,
rem S1078_SKIP_COST=1, S1078_SUBJECTS (rules ids).
setlocal enabledelayedexpansion
set "JOBFAIL=0"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
if "%S1078_HOME%"=="" set "S1078_HOME=%VT%\opus1078"
set "HOME1078=%S1078_HOME%"
set "REF=%~1"
if "%REF%"=="" set "REF=origin/opus/issue-1078"
if "%S1078_SHIPS%"=="" set "S1078_SHIPS=%VT%\build\godot"
if not exist "%HOME1078%\out" mkdir "%HOME1078%\out"
set "ST=%HOME1078%\out\result.txt"
echo shield1078 start %date% %time% ref=%REF% >> "%ST%"
rem Ryan's real game options are never touched (Board, Nov 19; the 1079 RUN5 pattern): every Godot start below runs in a
rem throwaway profile, and his battle_opts.json and board_look.cfg are hashed now and at the end; a change fails the job.
set "REALU=%APPDATA%\Godot\app_userdata\Voidsworn"
set "PCHK="
set "PBEFORE=%HOME1078%\out\real_profile_before_%RANDOM%%RANDOM%.txt"
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%PBEFORE%" 2>&1
if errorlevel 1 (
  echo FAILED: could not hash Ryan's real options before the run, nothing was started >> "%ST%"
  set "JOBFAIL=1"
  set "PCHK=1"
  goto finish
)
set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
rem the canonical watchdog: tools_live\<current.txt>\pc\tmo.bat (issue 1194, Board Nov 20), never build_b's or the clone's copy;
rem a missing pointer or watchdog fails the job before any step (fail closed). Its path and sha256 go in result.txt.
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
set "TMO="
if defined TLV if exist "%VT%\tools_live\%TLV%\pc\run_timeout.ps1" if exist "%VT%\tools_live\%TLV%\pc\tmo.bat" set "TMO=%VT%\tools_live\%TLV%\pc\tmo.bat"
if not defined TMO (
  echo FAILED: no usable watchdog in %VT%\tools_live ^(current.txt names "%TLV%"^), nothing was started >> "%ST%"
  set "JOBFAIL=1"
  goto finish
)
set "TMO_HASH="
for /f "delims=" %%H in ('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath $env:TMO).Hash"') do set "TMO_HASH=%%H"
if not defined TMO_HASH (
  echo FAILED: could not hash the watchdog %TMO%, nothing was started >> "%ST%"
  set "JOBFAIL=1"
  goto finish
)
echo watchdog %TMO% sha256 %TMO_HASH% >> "%ST%"
set "PC_GPU_ISSUE=1078"

set "R=%HOME1078%\repo"
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%HOME1078%\git.txt" 2>&1
git -C "%R%" fetch origin >> "%HOME1078%\git.txt" 2>&1
set "OUT="
call :safe_checkout %REF% first
if errorlevel 1 goto finish
for /f %%H in ('git -C "%R%" rev-parse --short^=8 HEAD') do set "SHA=%%H"
rem a fresh work folder per attempt, so a retry never mixes old stills, clip frames or json with new ones
set "ATT=%SHA%_%RANDOM%%RANDOM%"
if exist "%HOME1078%\work\%ATT%" set "ATT=%ATT%_b"
set "OUT=%HOME1078%\work\%ATT%"
set "RES=%HOME1078%\out\%ATT%"
if not exist "%RES%" mkdir "%RES%"
if not exist "%OUT%" mkdir "%OUT%"
echo commit %SHA% attempt %ATT%: results in out\%ATT% >> "%ST%"
set "PROF=%HOME1078%\profile_%ATT%"
if not exist "%PROF%\appdata" mkdir "%PROF%\appdata"
if not exist "%PROF%\appdata" (
  echo FAILED: could not make the throwaway profile %PROF%\appdata, no Godot was started >> "%ST%"
  set "JOBFAIL=1"
  goto finish
)
set "APPDATA=%PROF%\appdata"
set "LOCALAPPDATA=%PROF%\appdata"
echo throwaway profile %PROF%\appdata >> "%ST%"
copy /y "%PBEFORE%" "%RES%\real_profile_before.txt" > nul 2>&1
rem the installed hulls, copied fresh every attempt into this job's own clone (robocopy replaces every file whose size or time differs, so a reused
rem clone never keeps an old hull; the probe records each drawn ship's scene sha256 in its json), and the import cache
if exist "%S1078_SHIPS%\gen" robocopy "%S1078_SHIPS%\gen" "%R%\godot\gen" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%OUT%\copy_gen.txt" 2>&1
if exist "%S1078_SHIPS%\assets\ships" robocopy "%S1078_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XF a4_props.gd /NFL /NDL /NJH /NJS /R:1 /W:1 > "%OUT%\copy_ships.txt" 2>&1
if not exist "%R%\godot\.godot" if exist "%S1078_SHIPS%\.godot" robocopy "%S1078_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%OUT%\copy_cache.txt" 2>&1
set "PICTURE_STAMP_TOOL=%R%\tools\picture_provenance.py"
set "PICTURE_SOURCE_REPO=%R%"
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%OUT%\import.txt" 2>&1
echo imported %date% %time% >> "%ST%"
rem GLASS6 drew the old I8_37 scene although CD5 was published: rebuild the ship cache (gen\ships) from the copied
rem assets\ships, as the recipe's stage 7 install does (render\build_assets.gd --ships-only), so a newly installed hull is
rem never shadowed by a stale cached scene. Then log what the drawn subjects' files are.
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --script res://render/build_assets.gd -- --ships-only > "%OUT%\ships_cache.txt" 2>&1
if errorlevel 1 (
  echo FAILED: the ship cache rebuild failed, see %OUT%\ships_cache.txt >> "%ST%"
  set "JOBFAIL=1"
  goto finish
)
echo ship cache rebuilt from assets\ships %date% %time% >> "%ST%"
powershell -NoProfile -Command "foreach ($p in @((Join-Path $env:S1078_SHIPS 'assets\ships\I8_37\I8_37.glb'), (Join-Path $env:S1078_SHIPS 'gen\ships\I8_37.scn'), (Join-Path $env:R 'godot\assets\ships\I8_37\I8_37.glb'), (Join-Path $env:R 'godot\gen\ships\I8_37.scn'))) { if (Test-Path -LiteralPath $p) { 'file ' + $p + ' ' + (Get-Item -LiteralPath $p).LastWriteTime.ToString('s') + ' sha256 ' + (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash } else { 'absent ' + $p } }" >> "%ST%" 2>&1

if "%S1078_SKIP_LOOK%"=="1" goto flash
set "PROBE_OUT=%OUT%\look"
set "PROBE_CLIP=1"
set "PROBE_COST="
if not "%S1078_SUBJECTS%"=="" set "PROBE_SUBJECTS=%S1078_SUBJECTS%"
set "PC_GPU_MODE=shared"
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --script res://fx/test/shield_fail_probe.gd > "%OUT%\look_log.txt" 2>&1
findstr /c:"SHIELD1078_DONE" "%OUT%\look_log.txt" > nul
if errorlevel 1 (
  echo FAILED: the look pass did not finish, see %OUT%\look_log.txt >> "%ST%"
  set "JOBFAIL=1"
  goto finish
)
echo look pass done %date% %time% >> "%ST%"
rem bring the sheets out now, so a later step can never hold them back
copy /y "%OUT%\look\*.png" "%RES%\" > nul 2>&1
copy /y "%OUT%\look\*.json" "%RES%\" > nul 2>&1
copy /y "%OUT%\look_log.txt" "%RES%\" > nul 2>&1
rem clips: ffmpeg from PATH, else the one inside ComfyUI's portable Python (imageio_ffmpeg)
set "FF="
where ffmpeg > nul 2>&1 && set "FF=ffmpeg"
set "CPY=%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
rem the trellis venv carries imageio_ffmpeg too (Board, Nov 20)
if not exist "%CPY%" set "CPY=%USERPROFILE%\Downloads\trellis2\code\venv\Scripts\python.exe"
if "%FF%"=="" if exist "%CPY%" for /f "delims=" %%F in ('"%CPY%" -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())" 2^>nul') do set "FF=%%F"
if "%FF%"=="" (
  echo no ffmpeg on this PC: the Iron Mandate clip frames go to out\ for the cloud to encode, the rest stay in work\ >> "%ST%"
  for /d %%D in ("%OUT%\look\clip_h_boss_*") do robocopy "%%D" "%RES%\%%~nxD" f_*.jpg /NFL /NDL /NJH /NJS /R:1 /W:1 > nul
  goto flash
)
for /d %%D in ("%OUT%\look\clip_*") do (
  "%FF%" -y -loglevel error -framerate 30 -i "%%D\f_%%04d.jpg" -c:v libx264 -pix_fmt yuv420p -crf 20 "%OUT%\look\%%~nxD.mp4"
  if errorlevel 1 (
    echo FAILED: clip %%~nxD did not encode >> "%ST%"
    set "JOBFAIL=1"
  ) else (
    echo clip %%~nxD encoded >> "%ST%"
  )
)
echo clips done %date% %time% >> "%ST%"
copy /y "%OUT%\look\*.mp4" "%RES%\" > nul 2>&1

:flash
rem the flash pass (Artoo on PR 1170, R340): four Glasswright ships, then four Hullbreaker ships, fail at once at camera 170,
rem reduce flashing off and on, fitted and egg; screen luminance counted per frame the scene gate way. Shares the GPU.
if "%S1078_SKIP_FLASH%"=="1" goto cost
set "PROBE_OUT=%OUT%\flash"
set "PROBE_CLIP="
set "PROBE_COST="
set "PROBE_FLASH=1"
set "PC_GPU_MODE=shared"
call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --script res://fx/test/shield_fail_probe.gd > "%OUT%\flash_log.txt" 2>&1
set "PROBE_FLASH="
copy /y "%OUT%\flash_log.txt" "%RES%\" > nul 2>&1
findstr /c:"SHIELD1078_DONE" "%OUT%\flash_log.txt" > nul
if errorlevel 1 (
  echo FAILED: the flash pass did not finish ^(or a frame or still was empty^), see %OUT%\flash_log.txt >> "%ST%"
  set "JOBFAIL=1"
  goto cost
)
echo flash pass ran %date% %time% >> "%ST%"
rem the evidence must reach out\: the json and one still per row (2 factions x 2 shapes x 2 settings x 2 looks = 16), every copy checked
copy /y "%OUT%\flash\shield1078.json" "%RES%\flash.json" > nul 2>&1
if errorlevel 1 (
  echo FAILED: the flash json did not copy to %RES% >> "%ST%"
  set "JOBFAIL=1"
)
copy /y "%OUT%\flash\SHIELD1078_*_flash_*.png" "%RES%\" > nul 2>&1
if errorlevel 1 (
  echo FAILED: the flash stills did not copy to %RES% >> "%ST%"
  set "JOBFAIL=1"
)
copy /y "%OUT%\flash\SHIELD1078_*_flash_*.provenance.json" "%RES%\" > nul 2>&1
set "S1078_FROWS=0"
for /f %%C in ('findstr /c:"SHIELD1078 flash {" "%OUT%\flash_log.txt" ^| find /c /v ""') do set "S1078_FROWS=%%C"
set "S1078_FPNG=0"
for /f %%C in ('dir /b "%RES%\SHIELD1078_*_flash_*.png" 2^>nul ^| find /c /v ""') do set "S1078_FPNG=%%C"
if not "%S1078_FROWS%"=="16" (
  echo FAILED: the flash pass logged %S1078_FROWS% result rows, expected 16 >> "%ST%"
  set "JOBFAIL=1"
)
if not "%S1078_FPNG%"=="16" (
  echo FAILED: %S1078_FPNG% flash stills reached out\, expected 16 >> "%ST%"
  set "JOBFAIL=1"
)
rem the measured result, kept apart from "it ran": every row as the probe printed it, then the threshold verdict
findstr /c:"SHIELD1078 flash {" "%OUT%\flash_log.txt" >> "%ST%"
findstr /c:"\"pass\":false" "%OUT%\flash_log.txt" > nul
if errorlevel 1 (
  echo flash threshold: every row at or under 3 flashes a second >> "%ST%"
) else (
  echo flash threshold: OVER, a row above 3 flashes a second ^(see the rows above^) >> "%ST%"
)

:cost
if "%S1078_SKIP_COST%"=="1" goto done
set "PROBE_OUT=%OUT%\cost"
set "PROBE_CLIP="
set "PROBE_COST=1"
set "PROBE_FLASH="
set "PROBE_SHAPES=fitted,egg"
set "PC_GPU_MODE=solo"
rem a 20 minute ceiling: a hang can never hold the GPU solo for long (the pass takes about 8 minutes)
call "%TMO%" 1200 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --script res://fx/test/shield_fail_probe.gd > "%OUT%\cost_log.txt" 2>&1
set "PC_GPU_MODE="
findstr /c:"SHIELD1078_DONE" "%OUT%\cost_log.txt" > nul
if errorlevel 1 (
  echo FAILED: the cost pass did not finish, see %OUT%\cost_log.txt >> "%ST%"
  set "JOBFAIL=1"
  goto finish
)
echo cost pass done %date% %time% >> "%ST%"
copy /y "%OUT%\cost\shield1078.json" "%RES%\cost_branch.json" > nul 2>&1
copy /y "%OUT%\cost_log.txt" "%RES%\" > nul 2>&1

rem the same cost pass on main (today's look only, the probe copied in), so the numbers compare against main itself
copy /y "%R%\godot\fx\test\shield_fail_probe.gd" "%HOME1078%\probe_copy.gd" > nul
call :safe_checkout origin/main main
if errorlevel 1 (
  echo FAILED: cannot check out origin/main, no main cost numbers >> "%ST%"
  set "JOBFAIL=1"
  goto done
)
set "MSHA="
set "WANT="
for /f %%H in ('git -C "%R%" rev-parse --short^=8 HEAD') do set "MSHA=%%H"
for /f %%H in ('git -C "%R%" rev-parse --short^=8 origin/main') do set "WANT=%%H"
if not "%MSHA%"=="%WANT%" (
  echo FAILED: checkout is %MSHA%, origin/main is %WANT%, no main cost numbers >> "%ST%"
  set "JOBFAIL=1"
  goto done
)
rem the probe goes in under a name main does not track, so checking the branch out again never collides with it
copy /y "%HOME1078%\probe_copy.gd" "%R%\godot\fx\test\shield1078_main_probe.gd" > nul
rem a fresh folder per run, so an older run's json can never stand in for this one
set "MRUN=cost_main_%MSHA%_%RANDOM%%RANDOM%"
set "PROBE_OUT=%OUT%\%MRUN%"
set "PROBE_LOOKS=today"
set "PC_GPU_MODE=solo"
call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --script res://fx/test/shield1078_main_probe.gd > "%OUT%\cost_main_log.txt" 2>&1
set "PC_GPU_MODE="
set "PROBE_LOOKS="
findstr /c:"SHIELD1078_DONE" "%OUT%\cost_main_log.txt" > nul
if errorlevel 1 (
  echo FAILED: the main cost pass on %MSHA% did not finish, see cost_main_log.txt; no main cost numbers >> "%ST%"
  set "JOBFAIL=1"
  goto done
)
if not exist "%OUT%\%MRUN%\shield1078.json" (
  echo FAILED: the main cost pass on %MSHA% wrote no json; no main cost numbers >> "%ST%"
  set "JOBFAIL=1"
  goto done
)
echo main cost pass %MSHA% done in %MRUN% %date% %time% >> "%ST%"

:done
call :safe_checkout %SHA% back
if errorlevel 1 set "JOBFAIL=1"
call :profile_check
if "%JOBFAIL%"=="0" (
  echo DONE %SHA% %date% %time% >> "%ST%"
) else (
  echo RESULT: FAILED, see the FAILED lines above %date% %time% >> "%ST%"
)

:finish
if not defined PCHK call :profile_check
rem what the Board brings back: sheets, clips, json and logs (no clip frames)
copy /y "%OUT%\*_log.txt" "%RES%\" > nul 2>&1
if exist "%OUT%\look" copy /y "%OUT%\look\*.png" "%RES%\" > nul 2>&1
if exist "%OUT%\look" copy /y "%OUT%\look\*.json" "%RES%\" > nul 2>&1
if exist "%OUT%\look" copy /y "%OUT%\look\*.mp4" "%RES%\" > nul 2>&1
for /d %%D in ("%OUT%\cost*") do copy /y "%%D\shield1078.json" "%RES%\%%~nxD.json" > nul 2>&1
echo shield1078 end %date% %time% >> "%ST%"
if not "%JOBFAIL%"=="0" echo RESULT: FAILED >> "%ST%"
echo all done >> "%ST%"
endlocal & exit /b %JOBFAIL%

rem ---------------------------------------------------------------- :profile_check
rem hash Ryan's real options again and compare with the start (REALU was read before APPDATA was redirected)
:profile_check
set "PCHK=1"
set "PAFTER=%PBEFORE:before=after%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%PAFTER%" 2>&1
if defined RES copy /y "%PAFTER%" "%RES%\real_profile_after.txt" > nul 2>&1
fc /b "%PBEFORE%" "%PAFTER%" > nul
if errorlevel 1 (
  echo FAILED: Ryan's real options changed during the run ^(or could not be hashed^), see %PBEFORE% and %PAFTER% >> "%ST%"
  set "JOBFAIL=1"
) else (
  echo Ryan's real options unchanged ^(battle_opts.json, board_look.cfg^) >> "%ST%"
)
exit /b 0


rem ---------------------------------------------------------------- :safe_checkout REF TAG
rem Never a forced checkout (file loss, issue 1179; the ship_job.bat pattern). Save the clone's tracked changes first
rem (git status and a binary patch, in out\), stop if any is outside godot\assets\ships and the .import files (the only tracked
rem files this job writes: the installed hulls copied in, and the import), restore only those from the clone's own commit, then a plain checkout that
rem also refuses to overwrite ignored files, then copy the installed hulls in again.
:safe_checkout
set "SC_REF=%~1"
set "SC_TAG=%~2"
set "SC_DIR=%HOME1078%\out\checkout_%SC_TAG%_%RANDOM%"
set "SC_LIST="
set "SC_PATCH="
mkdir "%SC_DIR%"
if not exist "%SC_DIR%" (
  echo FAILED: checkout %SC_REF%: could not make %SC_DIR%, nothing was touched >> "%ST%"
  set "JOBFAIL=1"
  exit /b 1
)
rem fail closed: both backup writes must succeed, and a nonempty change list must have a nonempty patch (Artoo, PR 1190)
git -C "%R%" status --porcelain --untracked-files=no > "%SC_DIR%\clone_changes_before_checkout.txt" 2> "%SC_DIR%\backup_errors.txt"
if errorlevel 1 (
  echo FAILED: checkout %SC_REF%: could not list the clone's changes, nothing was touched >> "%ST%"
  set "JOBFAIL=1"
  exit /b 1
)
rem staged edits: the HEAD patch below records only the net worktree difference, so a staged change that the worktree undoes
rem would vanish from it and then be reset. Nothing in this job stages, so any staged change stops it (Artoo, PR 1170)
git -C "%R%" diff --cached --quiet >> "%SC_DIR%\backup_errors.txt" 2>&1
if errorlevel 1 (
  git -C "%R%" diff --cached --binary > "%SC_DIR%\clone_staged_changes.patch" 2>> "%SC_DIR%\backup_errors.txt"
  echo FAILED: checkout %SC_REF%: the clone has staged changes ^(saved in %SC_DIR%\clone_staged_changes.patch^) or git failed; nothing was touched >> "%ST%"
  set "JOBFAIL=1"
  exit /b 1
)
git -C "%R%" diff --binary HEAD > "%SC_DIR%\clone_changes_before_checkout.patch" 2>> "%SC_DIR%\backup_errors.txt"
if errorlevel 1 (
  echo FAILED: checkout %SC_REF%: could not save the patch, nothing was touched >> "%ST%"
  set "JOBFAIL=1"
  exit /b 1
)
for %%Z in ("%SC_DIR%\clone_changes_before_checkout.txt") do set "SC_LIST=%%~zZ"
for %%Z in ("%SC_DIR%\clone_changes_before_checkout.patch") do set "SC_PATCH=%%~zZ"
if not defined SC_LIST set "SC_LIST=-1"
if not defined SC_PATCH set "SC_PATCH=-1"
if %SC_LIST% LSS 0 (
  echo FAILED: checkout %SC_REF%: the change list was not written, nothing was touched >> "%ST%"
  set "JOBFAIL=1"
  exit /b 1
)
if %SC_LIST% GTR 0 if %SC_PATCH% LEQ 0 (
  echo FAILED: checkout %SC_REF%: changes are listed but the patch is empty, nothing was touched >> "%ST%"
  set "JOBFAIL=1"
  exit /b 1
)
rem expected: the copied hulls, and the .import files the headless import rewrites (the ship_job.bat fix, opus/issue-1174).
rem git filters the list itself: findstr $ needs a CR and git writes LF only, so a findstr \.import$ matched nothing (Board, run 3)
git -C "%R%" status --porcelain --untracked-files=no -- . ":(exclude)godot/assets/ships" ":(glob,exclude)godot/**/*.import" > "%SC_DIR%\clone_changes_unexpected.txt" 2>> "%SC_DIR%\backup_errors.txt"
if errorlevel 1 (
  echo FAILED: checkout %SC_REF%: git status of the clone failed, nothing was reset >> "%ST%"
  set "JOBFAIL=1"
  exit /b 1
)
for %%Z in ("%SC_DIR%\clone_changes_unexpected.txt") do if %%~zZ GTR 0 (
  echo FAILED: checkout %SC_REF%: the clone has local changes outside godot\assets\ships and the godot .import files, listed in %SC_DIR%\clone_changes_unexpected.txt and saved as a patch; nothing was reset >> "%ST%"
  set "JOBFAIL=1"
  exit /b 1
)
git -C "%R%" checkout -q HEAD -- godot/assets/ships >> "%HOME1078%\git.txt" 2>&1
if errorlevel 1 (
  echo FAILED: checkout %SC_REF%: could not restore godot\assets\ships, see git.txt >> "%ST%"
  set "JOBFAIL=1"
  exit /b 1
)
rem restore the rewritten .import files from the clone's own commit (saved in the patch above), as ship_job.bat does
git -C "%R%" checkout -q HEAD -- ":(glob)godot/**/*.import" >> "%HOME1078%\git.txt" 2>&1
if errorlevel 1 (
  echo FAILED: checkout %SC_REF%: could not restore the .import files, see git.txt >> "%ST%"
  set "JOBFAIL=1"
  exit /b 1
)
git -C "%R%" checkout -q --no-overwrite-ignore --detach %SC_REF% >> "%HOME1078%\git.txt" 2>&1
if errorlevel 1 (
  echo FAILED: checkout %SC_REF% refused, see git.txt; nothing was forced >> "%ST%"
  set "JOBFAIL=1"
  exit /b 1
)
echo checked out %SC_REF% safely, saved changes in %SC_DIR% >> "%ST%"
if exist "%S1078_SHIPS%\assets\ships" robocopy "%S1078_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XF a4_props.gd /NFL /NDL /NJH /NJS /R:1 /W:1 > "%SC_DIR%\copy_ships.txt" 2>&1
exit /b 0
