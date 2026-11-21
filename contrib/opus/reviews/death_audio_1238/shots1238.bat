@echo off
rem Issue 1238 pictures and a clip with sound for Ryan: Chorus cruiser, Chorus Bio-Titan and Glasswright cruiser deaths
rem (plus a Chorus frigate as the unchanged control), on main (before) and on opus/issue-1238 (after).
rem Strips: the look bench at cameras 170 and 60 (7 cells: the kill, mid-tell, just before the split, the split, then
rem 0.3, 1.0 and 2.5 s after). Clip: the same deaths at camera 60 with the game's death sounds, 5.5 s each, via
rem Godot's --write-movie (AVI with sound). The bench script and its rows always come from the branch.
rem Its own clone in Downloads\voidsworn_test\opus1238; hulls copied in from build\godot (else audit2), copy only.
rem Each run uses its own throwaway profile; your real settings are hashed before and after. Nothing on the PC is deleted.
rem Each Godot run goes through tmo.bat, so the GPU slots are respected.
rem Output: Downloads\voidsworn_test\opus1238\shots\<after|before>\  and status.txt beside them.
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus1238"
set "R=%H%\repo"
set "BR=opus/issue-1238"
rem Built ships: the shared PC build (build\godot), else the old audit2 checkout. LB_SHIPS overrides both (issue 1223).
if "%LB_SHIPS%"=="" if exist "%VT%\build\godot\gen" set "LB_SHIPS=%VT%\build\godot"
if "%LB_SHIPS%"=="" set "LB_SHIPS=%VT%\audit2\repo\godot"
set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "TMO=%VT%\tools\pc\tmo.bat"
if not exist "%TMO%" set "TMO=%R%\tools\pc\tmo.bat"
if not exist "%H%\bench" mkdir "%H%\bench"
set "ST=%H%\status.txt"
echo shots1238 start %date% %time% > "%ST%"
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%H%\git.txt" 2>&1
git -C "%R%" fetch origin main %BR% >> "%H%\git.txt" 2>&1
for %%F in (look_bench.gd look_bench.tscn look_moments_1238.json look_moments_1238_clip.json) do (
  git -C "%R%" show origin/%BR%:godot/bench/%%F > "%H%\bench\%%F"
  if errorlevel 1 (
    echo FAILED: no godot/bench/%%F on %BR% >> "%ST%"
    goto done
  )
)
call :one after origin/%BR%
call :one before origin/main
echo shots1238 done %date% %time% >> "%ST%"
:done
type "%ST%"
start "" "%H%\shots"
exit /b 0

rem ---- :one NAME REF
:one
set "NAME=%~1"
set "REF=%~2"
set "O=%H%\shots\%NAME%"
if not exist "%O%" mkdir "%O%"
git -C "%R%" checkout -f --detach %REF% >> "%H%\git.txt" 2>&1
if errorlevel 1 (
  echo FAILED: cannot check out %REF% >> "%ST%"
  exit /b 1
)
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt"
set /p SHA=<"%O%\commit.txt"
if exist "%LB_SHIPS%\gen" robocopy "%LB_SHIPS%\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if exist "%LB_SHIPS%\assets\ships" robocopy "%LB_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if not exist "%R%\godot\.godot" if exist "%LB_SHIPS%\.godot" robocopy "%LB_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
for %%F in (look_bench.gd look_bench.tscn look_moments_1238.json look_moments_1238_clip.json) do copy /y "%H%\bench\%%F" "%R%\godot\bench\%%F" > nul
set "PICTURE_SOURCE_REPO=%R%"
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
call :cap strips "--moments res://bench/look_moments_1238.json"
call :cap clip "--moments res://bench/look_moments_1238_clip.json --sound" clip
git -C "%R%" checkout -f --detach %REF% > nul 2>&1
exit /b 0

rem ---- :cap KIND "BENCH ARGS" [clip]: one bench run in its own throwaway profile (APPDATA), so your own settings and
rem saves are never opened for writing; the hashes of your real options and settings files are compared before and after.
:cap
set "CK=%~1"
set "P=%H%\profile\%NAME%_%CK%"
if not exist "%P%" mkdir "%P%"
call :hashes "%O%\real_before_%CK%.txt"
set "OLDAPP=%APPDATA%"
set "OLDLOC=%LOCALAPPDATA%"
set "APPDATA=%P%"
set "LOCALAPPDATA=%P%"
set "VS_CAPTURE_PROFILE=%P%"
set "MOVIE="
if "%~3"=="clip" set "MOVIE=--write-movie "%O%\D1238_%NAME%_deaths_with_sound.avi""
if not exist "%O%\%CK%" mkdir "%O%\%CK%"
call "%TMO%" 3600 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 %MOVIE% res://bench/look_bench.tscn -- --out "%O%\%CK%" --part moments --no-warm --commit %SHA% %~2 > "%O%\log_%CK%.txt" 2>&1
set "APPDATA=%OLDAPP%"
set "LOCALAPPDATA=%OLDLOC%"
set "VS_CAPTURE_PROFILE="
findstr /c:"LOOK_BENCH_DONE" "%O%\log_%CK%.txt" > nul && (echo done: %NAME% %CK% >> "%ST%") || (echo FAILED: %NAME% %CK%, see %O%\log_%CK%.txt >> "%ST%")
call :hashes "%O%\real_after_%CK%.txt"
fc /b "%O%\real_before_%CK%.txt" "%O%\real_after_%CK%.txt" > nul && (echo own settings untouched: %NAME% %CK% >> "%ST%") || (echo WARNING: own settings changed during %NAME% %CK% >> "%ST%")
exit /b 0

rem ---- :hashes FILE: hashes of the real profile's options, settings and look files (missing files listed as missing)
:hashes
set "U=%APPDATA%\Godot\app_userdata\Voidsworn"
> "%~1" echo real profile %U%
for %%F in (battle_opts.json settings.json board_look.cfg voidsworn_career.json voidsworn_campaign.json) do (
  if exist "%U%\%%F" (certutil -hashfile "%U%\%%F" SHA256 | findstr /v /c:"CertUtil" >> "%~1") else (echo %%F missing >> "%~1")
)
exit /b 0
