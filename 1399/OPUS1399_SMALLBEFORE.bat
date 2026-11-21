@echo off
title Opus 1399: small-ship wreck drift clip (smallbefore) - GPU job
rem Issue 1399 (R367, Ryan's "Full faction deaths"). Look bench stills of ship deaths at the pinned commit: Glasswright
rem i_wisp, i_song, i_boss; Eclipse d_scythe, d_harvester, d_boss; Ashfall A16 (c_boss) as today's shared-fire reference.
rem Each at stage 4 damage, then killed, at the battle camera (r170) and a close camera (0.62 of its length), with the
rem game's own settings (one-crack strained death on, quality max, Forward+). Stills: tell, split, core, wreck, settled.
rem TAG is "before" on today's code and "after" on the built faction deaths; the same script runs both.
rem Same guards as the 1077 jobs: the 1078 safe checkout (never forced), the installed-ships copy skipping manifest.json,
rem README.md, a4_props.gd and *.uid, a throwaway profile with Ryan's real battle_opts.json and board_look.cfg hashed
rem before and after, every Godot start through the canonical watchdog tools_live\<current>\pc\tmo.bat.
rem Writes only under opus1399\ (out_<TAG>_<A> and scratch_<TAG>_<A>, A the first unused attempt number; the clone at
rem opus1399\repo is made once if missing). Never deletes anything. Logs to result.txt; ends with "all done".
setlocal EnableDelayedExpansion
set EXPECT=ce38ea5628a1e43472ec24deac73a2a05e232d5c
set TAG=smallbefore
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1399
set C=%W%\repo
if not exist "%W%" mkdir "%W%"
set A=1
:findattempt
if exist "%W%\out_%TAG%_%A%" (set /a A+=1 & goto findattempt)
set O=%W%\out_%TAG%_%A%
set S=%W%\scratch_%TAG%_%A%
mkdir "%O%"
mkdir "%S%"
set RES=%O%\result.txt
rem The ships to capture (small hulls, all new builds: Warden V14_23, Harrow V15_37, Raider C13s_23, Gutship C14s_23); ships.txt is not read.
set SHIPS=warden,harrow,c_raider,c_reaver
set BAD=0
echo start %DATE% %TIME% attempt %A% tag %TAG% > "%RES%"
findstr /b /c:"GPU cleared" "%V%\gpu_go.txt" >nul 2>&1 || (echo gpu_go.txt is not GPU cleared: stopped >> "%RES%" & echo all done >> "%RES%" & exit /b 0)
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
if not exist "%C%\.git" (
  git clone -q https://github.com/rcbailey12/voidsworn.git "%C%" >> "%RES%" 2>&1
  if errorlevel 1 (set "FAILMSG=git clone into %C% failed" & goto fail)
)
git -C "%C%" config core.autocrlf false >> "%RES%" 2>&1
git -C "%C%" fetch -q --depth 1 origin %EXPECT% >> "%RES%" 2>&1
if errorlevel 1 (set "FAILMSG=git fetch of %EXPECT% failed" & goto fail)
call :safe_checkout FETCH_HEAD
if errorlevel 1 goto fail
set COMMIT=
for /f %%H in ('git -C "%C%" rev-parse HEAD') do set COMMIT=%%H
echo commit=%COMMIT% >> "%RES%"
if not "%COMMIT%"=="%EXPECT%" (set "FAILMSG=checked out %COMMIT%, expected %EXPECT%" & goto fail)
echo {"commit": "%COMMIT%"} > "%C%\godot\build_info.json"
robocopy "%V%\build\godot\assets\ships" "%C%\godot\assets\ships" /E /NFL /NDL /NJH /NP /XF manifest.json README.md a4_props.gd *.uid /XD test > "%O%\log_copy_ships.txt" 2>&1
set E=%ERRORLEVEL%
echo copy ships robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (set "FAILMSG=copy ships failed" & goto fail)
if exist "%V%\build\godot\gen" robocopy "%V%\build\godot\gen" "%C%\godot\gen" /E /NFL /NDL /NJH /NP > "%O%\log_copy_gen.txt" 2>&1
set E=%ERRORLEVEL%
echo copy gen robocopy %E% (0 to 7 is success) >> "%RES%"
if %E% GEQ 8 (set "FAILMSG=copy gen failed" & goto fail)
if not exist "%C%\godot\bench\opus1399" mkdir "%C%\godot\bench\opus1399"
copy /y "%C%\contrib\opus\faction_death_1399\capture.gd" "%C%\godot\bench\opus1399\" > nul
if errorlevel 1 (set "FAILMSG=copying the capture script failed" & goto fail)
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
set "TLV="
if exist "%V%\tools_live\current.txt" set /p TLV=<"%V%\tools_live\current.txt"
if not defined TLV (set "FAILMSG=tools_live\current.txt is missing or empty" & goto fail)
set "TM=%V%\tools_live\%TLV%\pc\tmo.bat"
if not exist "%TM%" (set "FAILMSG=no watchdog at %TM%" & goto fail)
echo watchdog %TM% >> "%RES%"
certutil -hashfile "%TM%" SHA256 >> "%RES%" 2>&1
set PC_GPU_WAIT_SECONDS=3600
set PC_GPU_ISSUE=1399
cd /d "%C%"
"%GD%" --version >> "%RES%" 2>&1
call "%TM%" 3600 "%GD%" --headless --path "%C%\godot" --import > "%O%\log_import.txt" 2>&1
set E=%ERRORLEVEL%
echo import exit %E% >> "%RES%"
if not "%E%"=="0" (set "FAILMSG=import failed" & goto fail)
call "%TM%" 5400 "%GD%" --path "%C%\godot" --rendering-method forward_plus --windowed --resolution 1920x1080 --fixed-fps 60 --script res://bench/opus1399/capture.gd -- "%S%" %SHIPS% %TAG% drift > "%O%\log_capture.txt" 2>&1
set E=%ERRORLEVEL%
echo capture exit %E% >> "%RES%"
findstr /c:"CAPTURE1399 DONE" "%O%\log_capture.txt" >nul 2>&1 || set BAD=1
if not "%E%"=="0" set BAD=1
rem the light sheets and the record come home; the stamped pngs stay in the scratch folder
for /d %%D in ("%S%\%TAG%_*") do (
  mkdir "%O%\stills\%%~nxD"
  copy /y "%%D\*_sheet.jpg" "%O%\stills\%%~nxD\" > nul || set BAD=1
)
copy /y "%S%\%TAG%_capture.json" "%O%\" > nul || set BAD=1
if not "!BAD!"=="0" (set "FAILMSG=capture failed or stills missing; see log_capture.txt" & goto fail)
for /f "tokens=3" %%F in ('dir /-c "%V%" ^| findstr /c:"bytes free"') do echo drive bytes free %%F >> "%RES%"
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
