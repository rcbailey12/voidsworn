@echo off
title Chorus spitter rebuild: C13 trial export and in-game shots (issue 1291) - GPU job
rem Issue 1291 (Ryan, Nov 20 2026: "mix of b and c for armor. Agree on full rebuild. Agree on color. Agree on test spitter"):
rem the rebuilt chorus_C13 (b_spitter, B20_11) from the shared Chorus kit: swellings and folds grown into the skin, armadillo
rem bands of grown chitin over the back, grown plates on the flanks, the grown paint (olive-brown hide, dark red veins,
rem matte), and the stage 5 surface-detail check; plus chorus_C11 (b_razor, B21_11) for its smaller, dimmer throat glands
rem (the orange "PLA" look) and the kit's rooms kept inside the skin (C13's lime disc). C11 keeps its R341 paint.
rem Same chain as R341_EXPORT_1234.bat (Artoo's two phases): stages 3 to 7 into a pinned clone's own godot project, the
rem private copy proven with staged_identity.py, the GPU readback, interiors, death seam and in-game shots, then publish into
rem build\godot through manifest_merge --install only when everything passed. The job's own watchdog is tools_live's current
rem tmo.bat, never the clone's.
rem   OPUS1291_EXPORT.bat                  the trial: C13 only, staged, checked and captured, nothing published
rem   OPUS1291_EXPORT.bat chorus_C11       another ship, same trial path
rem   set PUBLISH=1 first                  also publish into build\godot (only after Ryan accepts the look)
rem   PIN=<commit> builds another commit.
rem Each attempt clones fresh into opus1291\repo_<run> and stops if that folder exists. Writes only opus1291\, recipe\<ship>\
rem and, with PUBLISH=1, build\godot\assets\ships\<code>\ and the game's ship cache. Nothing is deleted. Exits 0 only when
rem everything passed; otherwise 1. result.txt ends in "all done".
setlocal enabledelayedexpansion
set V=%USERPROFILE%\Downloads\voidsworn_test
set W=%V%\opus1291
set RUN=%DATE:~-4%%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%_%RANDOM%
set RUN=%RUN: =0%
rem a fresh pinned clone per attempt (Artoo, PR 1308): never force-reset a checkout that may hold local changes
set "C=%W%\repo_%RUN%"
rem each attempt its own output and profile folder (Artoo, PR 1308): a later run never overwrites an earlier receipt
set "OUT=%W%\out_%RUN%"
if exist "%OUT%" exit /b 1
mkdir "%OUT%" || exit /b 1
set RES=%OUT%\result.txt
set BAD=
echo start %DATE% %TIME% > "%RES%"
rem the cloud round 10 look with the detail check measured at 1024 (run E: round D look, soft rim on the glow materials, satin veils (roughness .6), own out_<run> folder, opus/issue-1291)
if "%PIN%"=="" set PIN=7710e8429b62839823826fd673ac600f4f4c9a9f
if exist "%C%" (
  echo FAILED: %C% already exists, refusing to reuse it >> "%RES%"
  goto fail
)
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
git -C "%C%" checkout -q -f -B run1291 %PIN% >> "%RES%" 2>&1
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
set "PROF=%W%\profile_%RUN%"
if not exist "%PROF%\Roaming" mkdir "%PROF%\Roaming"
if not exist "%PROF%\Local" mkdir "%PROF%\Local"
set "APPDATA=%PROF%\Roaming"
set "LOCALAPPDATA=%PROF%\Local"
echo profile guard APPDATA=%APPDATA% >> "%RES%"
set RECIPE_NOPAUSE=1
set PC_GPU_WAIT_SECONDS=3600
set PC_GPU_ISSUE=1291
set "GAME=%V%\build\godot"
if not exist "%GAME%\project.godot" (
  echo FAILED: no game project at %GAME% >> "%RES%"
  goto fail
)
set "STAGE_GAME=%C%\godot"
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set BPY=%V%\blender\blender-4.5.14-windows-x64\4.5\python\bin\python.exe
rem the canonical watchdog: the current tools_live version, never the pinned clone's own
set TLV=
if exist "%V%\tools_live\current.txt" set /p TLV=<"%V%\tools_live\current.txt"
if not defined TLV (
  echo FAILED: tools_live\current.txt is missing or empty >> "%RES%"
  goto fail
)
set "TMO=%V%\tools_live\%TLV%\pc\tmo.bat"
if not exist "%TMO%" (
  echo FAILED: no watchdog at %TMO% >> "%RES%"
  goto fail
)
echo watchdog %TMO% >> "%RES%"
rem the trial is C13 alone (issue 1291); C11 and the rest follow only after Ryan accepts C13
set SHIPS=chorus_C13
if not "%1"=="" set SHIPS=%1
set STAGES=3_trace_hull 4_parts_kit 5_paint_bake 6_lod 7_export
if "%FULL%"=="1" set STAGES=1_concept_in 2_shape_ref %STAGES%
set DONE=
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

rem ---- phase 2: publish the checked exports into build\godot, only when asked (PUBLISH=1, after Ryan accepts) ----
if not "%PUBLISH%"=="1" (
  echo trial only: checked and captured, nothing published into build\godot >> "%RES%"
  echo all done PASS %DATE% %TIME% >> "%RES%"
  exit /b 0
)
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
