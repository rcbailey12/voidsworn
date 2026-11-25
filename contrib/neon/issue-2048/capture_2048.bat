@echo off
rem Issue 2048 (Build G): look bench before/after capture at cameras 170 and 26 for each item, per faction where it differs.
rem   capture_2048.bat [REF]     REF defaults to origin/neon/issue-2048
rem Queued by the Board on the GPU line after checks are green and review passes (R407).
rem Writes only under S2048_HOME (default %USERPROFILE%\Downloads\voidsworn_test\neon2048). Nothing is deleted.
rem Optional env: S2048_SHIPS (installed godot hulls folder, default build\godot), PROBE_ONLY (comma filter: shield,vent,terrain,idle).
setlocal enabledelayedexpansion
set "JOBFAIL=0"
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
if "%S2048_HOME%"=="" set "S2048_HOME=%VT%\neon2048"
set "HOME2048=%S2048_HOME%"
set "REF=%~1"
if "%REF%"=="" set "REF=origin/neon/issue-2048"
if "%S2048_SHIPS%"=="" set "S2048_SHIPS=%VT%\build\godot"
if not exist "%HOME2048%\out" mkdir "%HOME2048%\out"
set "ST=%HOME2048%\out\result.txt"
echo sweep2048 start %date% %time% ref=%REF% >> "%ST%"

rem Hash Ryan's real options before and after; redirect Godot profile to a throwaway folder.
set "REALU=%APPDATA%\Godot\app_userdata\Voidsworn"
set "PCHK="
set "PBEFORE=%HOME2048%\out\real_profile_before_%RANDOM%%RANDOM%.txt"
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%PBEFORE%" 2>&1
if errorlevel 1 (
  echo FAILED: could not hash Ryan's real options before the run, nothing was started >> "%ST%"
  set "JOBFAIL=1"
  set "PCHK=1"
  goto finish
)

set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"

rem Canonical watchdog (tools_live\<current.txt>\pc\tmo.bat); fail closed if missing.
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
set "TMO="
if defined TLV if exist "%VT%\tools_live\%TLV%\pc\run_timeout.ps1" if exist "%VT%\tools_live\%TLV%\pc\tmo.bat" set "TMO=%VT%\tools_live\%TLV%\pc\tmo.bat"
if not defined TMO (
  echo FAILED: no usable watchdog in %VT%\tools_live ^(current.txt names "%TLV%"^), nothing was started >> "%ST%"
  set "JOBFAIL=1"
  goto finish
)
set "PC_GPU_ISSUE=2048"

set "R=%HOME2048%\repo"
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%HOME2048%\git.txt" 2>&1
git -C "%R%" fetch origin >> "%HOME2048%\git.txt" 2>&1
set "OUT="

rem Pin full 40-char BEFORE (origin/main) and AFTER (REF) commit SHAs before running either capture.
set "BEFORE_SHA="
for /f %%H in ('git -C "%R%" rev-parse origin/main') do set "BEFORE_SHA=%%H"
set "AFTER_SHA="
for /f %%H in ('git -C "%R%" rev-parse %REF%') do set "AFTER_SHA=%%H"
if not defined BEFORE_SHA (
  echo FAILED: could not resolve origin/main SHA >> "%ST%"
  set "JOBFAIL=1"
  goto finish
)
if not defined AFTER_SHA (
  echo FAILED: could not resolve %REF% SHA >> "%ST%"
  set "JOBFAIL=1"
  goto finish
)

call :safe_checkout %AFTER_SHA% branch
if errorlevel 1 goto finish
set "SHA=%AFTER_SHA:~0,8%"
set "ATT=%SHA%_%RANDOM%%RANDOM%"
set "OUT=%HOME2048%\work\%ATT%"
set "RES=%HOME2048%\out\%ATT%"
mkdir "%OUT%" "%RES%"
echo after_sha %AFTER_SHA% before_sha %BEFORE_SHA% attempt %ATT%: results in out\%ATT% >> "%ST%"

set "PROF=%HOME2048%\profile_%ATT%"
mkdir "%PROF%\appdata"
if not exist "%PROF%\appdata" (
  echo FAILED: could not make throwaway profile %PROF%\appdata >> "%ST%"
  set "JOBFAIL=1"
  goto finish
)
set "APPDATA=%PROF%\appdata"
set "LOCALAPPDATA=%PROF%\appdata"
copy /y "%PBEFORE%" "%RES%\real_profile_before.txt" > nul 2>&1

if exist "%S2048_SHIPS%\gen" robocopy "%S2048_SHIPS%\gen" "%R%\godot\gen" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%OUT%\copy_gen.txt" 2>&1
if exist "%S2048_SHIPS%\assets\ships" robocopy "%S2048_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XF a4_props.gd /NFL /NDL /NJH /NJS /R:1 /W:1 > "%OUT%\copy_ships.txt" 2>&1
if not exist "%R%\godot\.godot" if exist "%S2048_SHIPS%\.godot" robocopy "%S2048_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > "%OUT%\copy_cache.txt" 2>&1
set "PICTURE_STAMP_TOOL=%R%\tools\picture_provenance.py"
set "PICTURE_SOURCE_REPO=%R%"
set "PROBE_BEFORE_SHA=%BEFORE_SHA%"
set "PROBE_AFTER_SHA=%AFTER_SHA%"
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%OUT%\import.txt" 2>&1
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --script res://render/build_assets.gd -- --ships-only > "%OUT%\ships_cache.txt" 2>&1
if errorlevel 1 (
  echo FAILED: ship cache rebuild failed, see %OUT%\ships_cache.txt >> "%ST%"
  set "JOBFAIL=1"
  goto finish
)

rem Keep a copy of the probe so the exact same script runs on pinned BEFORE_SHA.
copy /y "%R%\godot\fx\test\sweep_2048_probe.gd" "%HOME2048%\probe_copy.gd" > nul

rem Pass 1: AFTER (pinned AFTER_SHA)
set "PROBE_OUT=%OUT%"
set "PROBE_TAG=after"
set "PROBE_COMPOSE="
set "PC_GPU_MODE=shared"
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1280x720 --script res://fx/test/sweep_2048_probe.gd > "%OUT%\after_log.txt" 2>&1
if errorlevel 1 (
  echo FAILED: AFTER capture exited non-zero, see %OUT%\after_log.txt >> "%ST%"
  set "JOBFAIL=1"
  goto done
)
findstr /c:"SWEEP2048_DONE" "%OUT%\after_log.txt" > nul
if errorlevel 1 (
  echo FAILED: AFTER capture did not finish, see %OUT%\after_log.txt >> "%ST%"
  set "JOBFAIL=1"
  goto done
)
echo AFTER pass done %date% %time% >> "%ST%"

rem Pass 2: BEFORE (pinned BEFORE_SHA)
call :safe_checkout %BEFORE_SHA% main
if errorlevel 1 goto done
copy /y "%HOME2048%\probe_copy.gd" "%R%\godot\fx\test\sweep2048_main_probe.gd" > nul
set "PROBE_OUT=%OUT%"
set "PROBE_TAG=before"
set "PROBE_COMPOSE="
set "PC_GPU_MODE=shared"
call "%TMO%" 2400 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1280x720 --script res://fx/test/sweep2048_main_probe.gd > "%OUT%\before_log.txt" 2>&1
set "BERR=%ERRORLEVEL%"
del /q "%R%\godot\fx\test\sweep2048_main_probe.gd" > nul 2>&1
if not "%BERR%"=="0" (
  echo FAILED: BEFORE capture exited non-zero, see %OUT%\before_log.txt >> "%ST%"
  set "JOBFAIL=1"
  goto done
)
findstr /c:"SWEEP2048_DONE" "%OUT%\before_log.txt" > nul
if errorlevel 1 (
  echo FAILED: BEFORE capture on %BEFORE_SHA% did not finish, see %OUT%\before_log.txt >> "%ST%"
  set "JOBFAIL=1"
  goto done
)
echo BEFORE pass done %date% %time% >> "%ST%"

rem Pass 3: Compose 1280x720 before/after comparison sheets (top = BEFORE_SHA, bottom = AFTER_SHA)
call :safe_checkout %AFTER_SHA% back
if errorlevel 1 goto done
set "PROBE_OUT=%OUT%"
set "PROBE_TAG="
set "PROBE_COMPOSE=%OUT%\before;%OUT%\after"
call "%TMO%" 600 "%G%" --headless --path "%R%\godot" --script res://fx/test/sweep_2048_probe.gd > "%OUT%\compose_log.txt" 2>&1
set "CERR=%ERRORLEVEL%"
set "PROBE_COMPOSE="
if not "%CERR%"=="0" (
  echo FAILED: compose exited non-zero, see %OUT%\compose_log.txt >> "%ST%"
  set "JOBFAIL=1"
  goto done
)
findstr /c:"SWEEP2048_DONE" "%OUT%\compose_log.txt" > nul
if errorlevel 1 (
  echo FAILED: before/after sheet compose did not finish, see %OUT%\compose_log.txt >> "%ST%"
  set "JOBFAIL=1"
  goto done
)

rem Fail closed: require composed_manifest.json and non-zero composed PNGs matching manifest expected count.
if not exist "%OUT%\sheets\composed_manifest.json" (
  echo FAILED: composed_manifest.json missing >> "%ST%"
  set "JOBFAIL=1"
  goto done
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m = Get-Content -LiteralPath '%OUT%\sheets\composed_manifest.json' -Raw | ConvertFrom-Json; if ($m.expected -le 0 -or $m.composed -ne $m.expected) { exit 1 }; foreach ($f in $m.files) { if (-not (Test-Path -LiteralPath (Join-Path '%OUT%\sheets' $f))) { exit 1 } }"
if errorlevel 1 (
  echo FAILED: composed sheets count or files did not match composed_manifest.json >> "%ST%"
  set "JOBFAIL=1"
  goto done
)
echo compose verified %date% %time% >> "%ST%"

:done
call :profile_check
if "%JOBFAIL%"=="0" (
  echo DONE %AFTER_SHA% vs %BEFORE_SHA% %date% %time% >> "%ST%"
) else (
  echo RESULT: FAILED, see FAILED lines above %date% %time% >> "%ST%"
)

:finish
if not defined PCHK call :profile_check
if exist "%OUT%\sheets" copy /y "%OUT%\sheets\*.png" "%RES%\" > nul 2>&1
if exist "%OUT%\sheets" copy /y "%OUT%\sheets\*.provenance.json" "%RES%\" > nul 2>&1
if exist "%OUT%\sheets\composed_manifest.json" copy /y "%OUT%\sheets\composed_manifest.json" "%RES%\" > nul 2>&1
if exist "%OUT%\after\manifest.json" copy /y "%OUT%\after\manifest.json" "%RES%\manifest_after.json" > nul 2>&1
if exist "%OUT%\before\manifest.json" copy /y "%OUT%\before\manifest.json" "%RES%\manifest_before.json" > nul 2>&1
copy /y "%OUT%\*_log.txt" "%RES%\" > nul 2>&1
echo sweep2048 end %date% %time% >> "%ST%"
if not "%JOBFAIL%"=="0" echo RESULT: FAILED >> "%ST%"
echo all done >> "%ST%"
endlocal & exit /b %JOBFAIL%

:profile_check
set "PCHK=1"
set "PAFTER=%PBEFORE:before=after%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($f in 'battle_opts.json','board_look.cfg') { $p = Join-Path $env:REALU $f; if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash + ' ' + $f } else { 'absent ' + $f } }" > "%PAFTER%" 2>&1
if defined RES copy /y "%PAFTER%" "%RES%\real_profile_after.txt" > nul 2>&1
fc /b "%PBEFORE%" "%PAFTER%" > nul
if errorlevel 1 (
  echo FAILED: Ryan's real options changed during the run >> "%ST%"
  set "JOBFAIL=1"
) else (
  echo Ryan's real options unchanged ^(battle_opts.json, board_look.cfg^) >> "%ST%"
)
exit /b 0

:safe_checkout
set "SC_REF=%~1"
set "SC_TAG=%~2"
git -C "%R%" checkout -q HEAD -- godot/assets/ships >> "%HOME2048%\git.txt" 2>&1
git -C "%R%" checkout -q HEAD -- ":(glob)godot/**/*.import" >> "%HOME2048%\git.txt" 2>&1
git -C "%R%" checkout -q --no-overwrite-ignore --detach %SC_REF% >> "%HOME2048%\git.txt" 2>&1
if errorlevel 1 (
  echo FAILED: checkout %SC_REF% refused, see git.txt >> "%ST%"
  set "JOBFAIL=1"
  exit /b 1
)
if exist "%S2048_SHIPS%\assets\ships" robocopy "%S2048_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XF a4_props.gd /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
exit /b 0
