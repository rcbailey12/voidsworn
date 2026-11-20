@echo off
rem Issue 1237: three capitals dying at once, timed before (main) and after (opus/issue-1237).
rem Three A16 at the battle camera, 1920x1080, Forward+, --fixed-fps 60. Per ref: the prepared run three times (the pool
rem and sleep measure, gated) and the cold run once (a stress case, reported, not gated). Every Godot launch goes through
rem tmo.bat with the GPU solo (R293) and its own temp profile (PR 1249); your real settings are hashed before and after.
rem Its own clone in Downloads\voidsworn_test\opus1237; built ships copied in from Downloads\voidsworn_test\build\godot (copy only).
rem Each run writes to a fresh folder: Downloads\voidsworn_test\opus1237\out\<run stamp>\<after|before>\ and status.txt there.
rem Exit code (Artoo on PR 1255): 0 only when every step ran, both commits are recorded, each AFTER prepared run passed its
rem gate (prepared, 3 of 3 fractured, p99 inside 12.5 ms, Jolt idle within 8 s) with exit 0, each main prepared run is at
rem least valid (prepared, 3 of 3 fractured; its timing and rest misses are the baseline, reported only), nothing leaked
rem at quit and your settings are unchanged.
rem Nothing is deleted.
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus1237"
set "R=%H%\repo"
set "BR=opus/issue-1237"
if "%LB_SHIPS%"=="" set "LB_SHIPS=%VT%\build\godot"
set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "TMO=%VT%\tools\pc\tmo.bat"
if not exist "%TMO%" set "TMO=%R%\tools\pc\tmo.bat"
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%T"
set "RUN=%H%\out\%STAMP%"
if exist "%RUN%" (
  echo FAILED: run folder %RUN% already exists
  exit /b 1
)
mkdir "%RUN%"
set "ST=%RUN%\status.txt"
set /a FAILS=0
echo timing1237 start %date% %time% > "%ST%"
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%RUN%\git.txt" 2>&1
git -C "%R%" fetch origin main %BR% >> "%RUN%\git.txt" 2>&1
if errorlevel 1 (
  echo FAILED: git fetch >> "%ST%"
  set /a FAILS+=1
  goto done
)
git -C "%R%" show origin/%BR%:contrib/opus/multi_death_1237/capture.gd > "%RUN%\capture1237.gd"
if errorlevel 1 (
  echo FAILED: no capture script on %BR% >> "%ST%"
  set /a FAILS+=1
  goto done
)
for /f %%S in ('git -C "%R%" rev-parse origin/%BR%') do set "SHA_AFTER=%%S"
for /f %%S in ('git -C "%R%" rev-parse origin/main') do set "SHA_BEFORE=%%S"
if "%SHA_AFTER%"=="" (echo FAILED: no branch commit >> "%ST%" & set /a FAILS+=1 & goto done)
if "%SHA_BEFORE%"=="" (echo FAILED: no main commit >> "%ST%" & set /a FAILS+=1 & goto done)
echo after = %BR% %SHA_AFTER% >> "%ST%"
echo before = main %SHA_BEFORE% >> "%ST%"
call :one after %SHA_AFTER%
call :one before %SHA_BEFORE%
:done
echo timing1237 end %date% %time%, failures: %FAILS% >> "%ST%"
type "%ST%"
start "" "%RUN%"
if %FAILS% GTR 0 exit /b 1
exit /b 0

rem ---- :one NAME SHA
:one
set "NAME=%~1"
set "SHA=%~2"
set "O=%RUN%\%NAME%"
mkdir "%O%"
git -C "%R%" checkout -f --detach %SHA% >> "%RUN%\git.txt" 2>&1
if errorlevel 1 (
  echo FAILED: cannot check out %NAME% %SHA% >> "%ST%"
  set /a FAILS+=1
  exit /b 1
)
git -C "%R%" rev-parse HEAD > "%O%\commit.txt"
if exist "%LB_SHIPS%\gen" robocopy "%LB_SHIPS%\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if exist "%LB_SHIPS%\assets\ships" robocopy "%LB_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if not exist "%R%\godot\.godot" if exist "%LB_SHIPS%\.godot" robocopy "%LB_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
copy /y "%RUN%\capture1237.gd" "%R%\godot\bench\capture1237.gd" > nul
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
if errorlevel 1 (
  echo FAILED: import %NAME%, see %O%\import.txt >> "%ST%"
  set /a FAILS+=1
  exit /b 1
)
call :cap prepared 1
call :cap prepared 2
call :cap prepared 3
call :cap cold 1
git -C "%R%" checkout -f --detach %SHA% > nul 2>&1
exit /b 0

rem ---- :cap MODE SESSION: one timed run, GPU solo, fresh output folder; checked for its result, leaks and your settings.
:cap
set "CK=%~1_s%~2"
set "L=%O%\log_%CK%.txt"
mkdir "%O%\%CK%"
call :hashes "%O%\real_before_%CK%.txt"
set "PC_GPU_MODE=solo"
set "TMO_STEP=capture1237_%NAME%_%CK%"
set "CAPTURE1237_SHA=%SHA%"
call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --script res://bench/capture1237.gd -- %~1 "%O%\%CK%" > "%L%" 2>&1
set "CODE=%ERRORLEVEL%"
set "PC_GPU_MODE="
set "TMO_STEP="
set "CAPTURE1237_SHA="
findstr /b /c:"CAPTURE1237 prepared" /c:"CAPTURE1237 cold" /c:"CAPTURE1237 GATE" "%L%" > "%O%\summary_%CK%.txt"
for /f "usebackq delims=" %%Z in ("%O%\summary_%CK%.txt") do echo %NAME% %CK%: %%Z >> "%ST%"
rem Accepted: DONE with exit 0; or, on main only, a valid run that MISSES (exit non-zero, reported as the baseline).
rem INVALID (not prepared, or fewer than 3 real fractures) fails on both arms: it is no baseline and no proof.
set "RES=broken"
findstr /c:"CAPTURE1237 DONE" "%L%" > nul && set "RES=done"
findstr /c:"CAPTURE1237 GATE prepared MISS" "%L%" > nul && set "RES=miss"
findstr /c:"CAPTURE1237 GATE prepared INVALID" "%L%" > nul && set "RES=invalid"
if not exist "%O%\%CK%\%~1.json" set "RES=nojson"
if "%RES%"=="done" if not "%CODE%"=="0" set "RES=badexit"
if "%RES%"=="miss" if "%CODE%"=="0" set "RES=badexit"
if "%RES%"=="done" goto cap_ok
if "%RES%"=="miss" if "%NAME%"=="before" (
  echo baseline: %NAME% %CK% is a valid run over the line ^(reported, not a failure^) >> "%ST%"
  goto cap_ok
)
echo FAILED: %NAME% %CK% result %RES% ^(exit %CODE%^), see %L% >> "%ST%"
set /a FAILS+=1
:cap_ok
findstr /i /c:"leaked" /c:"still in use at exit" "%L%" > "%O%\leaks_%CK%.txt"
if not errorlevel 1 (
  echo FAILED: leaks at quit, %NAME% %CK%, see leaks_%CK%.txt >> "%ST%"
  set /a FAILS+=1
) else (
  echo no leaks at quit: %NAME% %CK% >> "%ST%"
)
call :hashes "%O%\real_after_%CK%.txt"
fc /b "%O%\real_before_%CK%.txt" "%O%\real_after_%CK%.txt" > nul
if errorlevel 1 (
  echo FAILED: your own settings changed during %NAME% %CK% >> "%ST%"
  set /a FAILS+=1
) else (
  echo own settings untouched: %NAME% %CK% >> "%ST%"
)
exit /b 0

rem ---- :hashes FILE: hashes of the real profile's options, settings and look files (missing files listed as missing)
:hashes
set "U=%APPDATA%\Godot\app_userdata\Voidsworn"
> "%~1" echo real profile %U%
for %%F in (battle_opts.json settings.json board_look.cfg voidsworn_career.json voidsworn_campaign.json) do (
  if exist "%U%\%%F" (certutil -hashfile "%U%\%%F" SHA256 | findstr /v /c:"CertUtil" >> "%~1") else (echo %%F missing >> "%~1")
)
exit /b 0
