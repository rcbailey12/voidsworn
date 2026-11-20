@echo off
rem Issue 1237: three capitals dying at once, timed before (main) and after (opus/issue-1237).
rem Three A16 at the battle camera, 1920x1080, Forward+, --fixed-fps 60. Per ref: the prepared run three times (the pool
rem and sleep measure) and the cold run once (the stress case). Every Godot launch goes through tmo.bat with the GPU solo
rem (R293) and a throwaway profile (issue 1228); your real settings are hashed before and after. Nothing is deleted.
rem Its own clone in Downloads\voidsworn_test\opus1237; built ships copied in from Downloads\voidsworn_test\build\godot (copy only).
rem Output: Downloads\voidsworn_test\opus1237\out\<after|before>\  (json per run, logs) and status.txt.
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
if not exist "%H%" mkdir "%H%"
set "ST=%H%\status.txt"
echo timing1237 start %date% %time% > "%ST%"
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%H%\git.txt" 2>&1
git -C "%R%" fetch origin main %BR% >> "%H%\git.txt" 2>&1
git -C "%R%" show origin/%BR%:contrib/opus/multi_death_1237/capture.gd > "%H%\capture1237.gd"
if errorlevel 1 (
  echo FAILED: no capture script on %BR% >> "%ST%"
  goto done
)
call :one after origin/%BR%
call :one before origin/main
echo timing1237 done %date% %time% >> "%ST%"
:done
type "%ST%"
start "" "%H%\out"
exit /b 0

rem ---- :one NAME REF
:one
set "NAME=%~1"
set "REF=%~2"
set "O=%H%\out\%NAME%"
if not exist "%O%" mkdir "%O%"
git -C "%R%" checkout -f --detach %REF% >> "%H%\git.txt" 2>&1
if errorlevel 1 (
  echo FAILED: cannot check out %REF% >> "%ST%"
  exit /b 1
)
git -C "%R%" log -1 --format=%%H > "%O%\commit.txt"
if exist "%LB_SHIPS%\gen" robocopy "%LB_SHIPS%\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if exist "%LB_SHIPS%\assets\ships" robocopy "%LB_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if not exist "%R%\godot\.godot" if exist "%LB_SHIPS%\.godot" robocopy "%LB_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
copy /y "%H%\capture1237.gd" "%R%\godot\bench\capture1237.gd" > nul
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
call :cap prepared 1
call :cap prepared 2
call :cap prepared 3
call :cap cold 1
git -C "%R%" checkout -f --detach %REF% > nul 2>&1
exit /b 0

rem ---- :cap MODE SESSION: one timed run, GPU solo, its own throwaway profile; the log is checked for leaks at quit.
:cap
set "CK=%~1_s%~2"
set "P=%H%\profile\%NAME%_%CK%"
if not exist "%P%" mkdir "%P%"
call :hashes "%O%\real_before_%CK%.txt"
set "OLDAPP=%APPDATA%"
set "OLDLOC=%LOCALAPPDATA%"
set "APPDATA=%P%"
set "LOCALAPPDATA=%P%"
set "VS_CAPTURE_PROFILE=%P%"
set "PC_GPU_MODE=solo"
set "TMO_STEP=capture1237_%NAME%_%CK%"
if not exist "%O%\%CK%" mkdir "%O%\%CK%"
call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --script res://bench/capture1237.gd -- %~1 "%O%\%CK%" > "%O%\log_%CK%.txt" 2>&1
set "PC_GPU_MODE="
set "TMO_STEP="
set "APPDATA=%OLDAPP%"
set "LOCALAPPDATA=%OLDLOC%"
set "VS_CAPTURE_PROFILE="
findstr /c:"CAPTURE1237 DONE" "%O%\log_%CK%.txt" > nul && (findstr /b /c:"CAPTURE1237 prepared" /c:"CAPTURE1237 cold" "%O%\log_%CK%.txt" >> "%ST%") || (echo FAILED: %NAME% %CK%, see %O%\log_%CK%.txt >> "%ST%")
findstr /i /c:"leaked" /c:"still in use at exit" "%O%\log_%CK%.txt" > "%O%\leaks_%CK%.txt" && (echo LEAKS at quit: %NAME% %CK%, see leaks_%CK%.txt >> "%ST%") || (echo no leaks at quit: %NAME% %CK% >> "%ST%")
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
