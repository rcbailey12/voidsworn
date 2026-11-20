@echo off
title Opus 1077 seam fix proof: death seam check on S8 and S9, headless - no GPU
rem Issue 1077 follow-up (Board, Nov 20: S8 V1b_r_23 and S9 V14_23 failed the death seam check after PR 1286, 87 and 158
rem inside triangles outside their piece's hull). The fix: a strained death keeps no lengthwise joint. On the pinned commit
rem this runs death_seam_check headless on both built Sunward capitals (copied read-only from the 1158 job folders into this
rem job's scratch folder), with the strained death (the default) and with it off. PASSED only when all four report
rem failures=0. Same guards as pass 6: the 1078 safe checkout, tools_live tmo, the throwaway profile with Ryan's real options
rem hashed before and after, the ships copy skipping manifest.json, README.md, a4_props.gd and *.uid.
rem Writes only under opus1077\ (out_seamfix_<A> and scratch_seamfix_<A>). Never deletes anything. Ends with "all done".
setlocal EnableDelayedExpansion
set EXPECT=686ee5d658c48740e80c400e66c27a14c05c9c40
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1077
set C=%W%\repo
set A=1
:findattempt
if exist "%W%\out_seamfix_%A%" (set /a A+=1 & goto findattempt)
set O=%W%\out_seamfix_%A%
set S=%W%\scratch_seamfix_%A%
mkdir "%O%"
mkdir "%S%"
set RES=%O%\result.txt
set BAD=0
echo start %DATE% %TIME% attempt %A% > "%RES%"
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
if not exist "%C%\.git" (set "FAILMSG=no clone at %C%" & goto fail)
git -C "%C%" fetch -q --depth 1 origin %EXPECT% >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=git fetch of %EXPECT% failed" & goto fail)
call :safe_checkout FETCH_HEAD
if errorlevel 1 goto fail
set COMMIT=
for /f %%H in ('git -C "%C%" rev-parse HEAD') do set COMMIT=%%H
echo commit=%COMMIT% >> "%RES%"
if not "%COMMIT%"=="%EXPECT%" (set "FAILMSG=checked out %COMMIT%, expected %EXPECT%" & goto fail)
echo {"commit": "%COMMIT%"} > "%C%\godot\build_info.json"
rem the installed ships and generated hulls, copied (robocopy /E only adds and updates; exit 0 to 7 is success, 8+ failed)
robocopy "%V%\build\godot\assets\ships" "%C%\godot\assets\ships" /E /NFL /NDL /NJH /NP /XF manifest.json README.md a4_props.gd *.uid > "%O%\log_copy_ships.txt" 2>&1
set E=%ERRORLEVEL%
echo copy ships robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (set "FAILMSG=copy ships failed" & goto fail)
if exist "%V%\build\godot\gen" robocopy "%V%\build\godot\gen" "%C%\godot\gen" /E /NFL /NDL /NJH /NP > "%O%\log_copy_gen.txt" 2>&1
set E=%ERRORLEVEL%
echo copy gen robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (set "FAILMSG=copy gen failed" & goto fail)
certutil -hashfile "%C%\godot\assets\ships\C19_51\C19_51.glb" SHA256 >> "%RES%" 2>&1
rem the throwaway profile: Ryan's real options are hashed first, then every Godot start below uses the profile
set "REALU=%APPDATA%\Godot\app_userdata\Voidsworn"
set N=1
:findprof
if exist "%W%\profile_%N%" (set /a N+=1 & goto findprof)
set "PROF=%W%\profile_%N%"
mkdir "%PROF%\appdata"
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%O%\real_profile_before.txt" 2>&1
set "APPDATA=%PROF%\appdata"
set "LOCALAPPDATA=%PROF%\appdata"
echo throwaway profile %PROF%\appdata >> "%RES%"
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
rem the canonical watchdog: tools_live's current version (named in tools_live\current.txt), never the pinned clone's own
set "TLV="
if exist "%V%\tools_live\current.txt" set /p TLV=<"%V%\tools_live\current.txt"
if not defined TLV (set "FAILMSG=tools_live\current.txt is missing or empty" & goto fail)
set "TM=%V%\tools_live\%TLV%\pc\tmo.bat"
if not exist "%TM%" (set "FAILMSG=no watchdog at %TM%" & goto fail)
if not exist "%V%\tools_live\%TLV%\pc\run_timeout.ps1" (set "FAILMSG=no run_timeout.ps1 beside %TM%" & goto fail)
echo watchdog %TM% >> "%RES%"
certutil -hashfile "%TM%" SHA256 >> "%RES%" 2>&1
certutil -hashfile "%V%\tools_live\%TLV%\pc\run_timeout.ps1" SHA256 >> "%RES%" 2>&1
cd /d "%C%"
"%GD%" --version >> "%RES%" 2>&1
call "%TM%" 3600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
set E=%ERRORLEVEL%
echo import exit %E% >> "%RES%"
if not "%E%"=="0" (set "FAILMSG=import failed" & goto fail)
set E=%ERRORLEVEL%
call "%TM%" 1800 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%C%\godot\assets\ships\C19_51\C19_51.glb" > "%O%\log_death_seam.txt" 2>&1
set E=%ERRORLEVEL%
echo death seam exit %E% >> "%RES%"
if not "%E%"=="0" (set "FAILMSG=death seam check failed" & goto fail)
rem the two built capitals, copied read-only from the 1158 job folders
copy /y "%V%\opus1158e8\repo\godot\assets\ships\V1b_r_23\V1b_r_23.glb" "%S%\" > nul || (set "FAILMSG=no S8 glb in opus1158e8" & goto fail)
copy /y "%V%\opus1158e9\repo\godot\assets\ships\V14_23\V14_23.glb" "%S%\" > nul || (set "FAILMSG=no S9 glb in opus1158e9" & goto fail)
certutil -hashfile "%S%\V1b_r_23.glb" SHA256 >> "%RES%" 2>&1
certutil -hashfile "%S%\V14_23.glb" SHA256 >> "%RES%" 2>&1
for %%G in (V1b_r_23 V14_23) do for %%M in (strain off) do (
  set "VS_DEATH_STORY=%%M"
  call "%TM%" 1800 "%GD%" --headless --path "%C%\godot" --script res://fx/test/death_seam_check.gd -- "%S%\%%G.glb" > "%O%\log_seam_%%G_%%M.txt" 2>&1
  set E=!ERRORLEVEL!
  echo seam %%G %%M exit !E! >> "%RES%"
  findstr /c:"DEATH_SEAM inside_triangles" "%O%\log_seam_%%G_%%M.txt" >> "%RES%"
  if not "!E!"=="0" set BAD=1
  findstr /c:"DEATH_SEAM failures=0" "%O%\log_seam_%%G_%%M.txt" >nul 2>&1 || set BAD=1
)
set "VS_DEATH_STORY="
if not "!BAD!"=="0" (set "FAILMSG=a death seam run failed, see log_seam_*.txt" & goto fail)
call :realcheck
if errorlevel 1 (set "FAILMSG=Ryan's real options changed during the run; see real_profile_*.txt" & goto fail)
echo real options unchanged >> "%RES%"
echo PASSED >> "%RES%"
echo all done %DATE% %TIME% >> "%RES%"
exit /b 0
:realcheck
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%O%\real_profile_after.txt" 2>&1
fc /b "%O%\real_profile_before.txt" "%O%\real_profile_after.txt" > nul
exit /b %ERRORLEVEL%
:fail
echo FAILED: %FAILMSG% >> "%RES%"
if defined REALU (call :realcheck & if errorlevel 1 (echo FAILED: Ryan's real options changed during the run >> "%RES%") else (echo real options unchanged >> "%RES%"))
echo all done %DATE% %TIME% >> "%RES%"
exit /b 1

rem ---------------------------------------------------------------- :safe_checkout REF (from tools/pc/jobs/shield_looks_1078.bat)
rem Never a forced checkout (file loss, issue 1179). Save the clone's tracked changes first (git status and a binary patch, in
rem the output folder), stop if any is outside godot\assets\ships and the .import files (the only tracked files these jobs
rem write), restore only those from the clone's own commit, then a plain checkout that also refuses to overwrite ignored files.
:safe_checkout
set "SC_REF=%~1"
set "SC_DIR=%O%\checkout_%RANDOM%"
set "SC_LIST="
set "SC_PATCH="
mkdir "%SC_DIR%"
if not exist "%SC_DIR%" (set "FAILMSG=checkout %SC_REF%: could not make %SC_DIR%, nothing was touched" & exit /b 1)
git -C "%C%" status --porcelain --untracked-files=no > "%SC_DIR%\clone_changes_before_checkout.txt" 2> "%SC_DIR%\backup_errors.txt"
if errorlevel 1 (set "FAILMSG=checkout %SC_REF%: could not list the clone's changes, nothing was touched" & exit /b 1)
git -C "%C%" diff --cached --quiet >> "%SC_DIR%\backup_errors.txt" 2>&1
if errorlevel 1 (
  git -C "%C%" diff --cached --binary > "%SC_DIR%\clone_staged_changes.patch" 2>> "%SC_DIR%\backup_errors.txt"
  set "FAILMSG=checkout %SC_REF%: the clone has staged changes (saved in %SC_DIR%) or git failed; nothing was touched"
  exit /b 1
)
git -C "%C%" diff --binary HEAD > "%SC_DIR%\clone_changes_before_checkout.patch" 2>> "%SC_DIR%\backup_errors.txt"
if errorlevel 1 (set "FAILMSG=checkout %SC_REF%: could not save the patch, nothing was touched" & exit /b 1)
for %%Z in ("%SC_DIR%\clone_changes_before_checkout.txt") do set "SC_LIST=%%~zZ"
for %%Z in ("%SC_DIR%\clone_changes_before_checkout.patch") do set "SC_PATCH=%%~zZ"
if not defined SC_LIST set "SC_LIST=-1"
if not defined SC_PATCH set "SC_PATCH=-1"
if %SC_LIST% LSS 0 (set "FAILMSG=checkout %SC_REF%: the change list was not written, nothing was touched" & exit /b 1)
if %SC_LIST% GTR 0 if %SC_PATCH% LEQ 0 (set "FAILMSG=checkout %SC_REF%: changes are listed but the patch is empty, nothing was touched" & exit /b 1)
git -C "%C%" status --porcelain --untracked-files=no -- . ":(exclude)godot/assets/ships" ":(glob,exclude)godot/**/*.import" > "%SC_DIR%\clone_changes_unexpected.txt" 2>> "%SC_DIR%\backup_errors.txt"
if errorlevel 1 (set "FAILMSG=checkout %SC_REF%: git status of the clone failed, nothing was reset" & exit /b 1)
for %%Z in ("%SC_DIR%\clone_changes_unexpected.txt") do if %%~zZ GTR 0 (set "FAILMSG=checkout %SC_REF%: the clone has local changes outside godot\assets\ships and the .import files, listed in %SC_DIR%; nothing was reset" & exit /b 1)
git -C "%C%" checkout -q HEAD -- godot/assets/ships >> "%SC_DIR%\git.txt" 2>&1
if errorlevel 1 (set "FAILMSG=checkout %SC_REF%: could not restore godot\assets\ships, see %SC_DIR%\git.txt" & exit /b 1)
git -C "%C%" checkout -q HEAD -- ":(glob)godot/**/*.import" >> "%SC_DIR%\git.txt" 2>&1
if errorlevel 1 (set "FAILMSG=checkout %SC_REF%: could not restore the .import files, see %SC_DIR%\git.txt" & exit /b 1)
git -C "%C%" checkout -q --no-overwrite-ignore --detach %SC_REF% >> "%SC_DIR%\git.txt" 2>&1
if errorlevel 1 (set "FAILMSG=checkout %SC_REF% refused, see %SC_DIR%\git.txt; nothing was forced" & exit /b 1)
echo checked out %SC_REF% safely, saved changes in %SC_DIR% >> "%RES%"
exit /b 0
