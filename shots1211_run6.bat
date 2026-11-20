@echo off
rem Issue 1211 pictures for Ryan, run 6 (gun tracers, a shield that breaks on the second hit, real 1080 and 4K windows): one enemy volley at your ship, in a nebula and in clear space,
rem at 1080p and 4K, on main just before PR 1220 (before, f50c339a) and on main at ab6b3258 with PR 1256 and the clean shield collapse (after), plus a short 720p nebula clip of each.
rem Run 3 changes: before pinned to the commit before the fix (main now has it), numbers clear of the name plate, the capture accepts run_timeout's own throwaway profile (PR 1249),
rem a 4K case is skipped (not failed) when the screen is not 4K at that moment, and the clip is 720p so it fits the relay.
rem Its own clone in Downloads\voidsworn_test\opus1211_run6; built hulls copied in from %VT%\build\godot (copy only).
rem Each capture runs in its own throwaway profile; your real settings are hashed before and after. Nothing on the PC is deleted. Each Godot run goes through tmo.bat, so the GPU slots are respected.
rem Output: Downloads\voidsworn_test\opus1211_run6\shots\<before|after>\  and status.txt beside them.
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus1211_run6"
set "R=%H%\repo"
set "BEFORE=f50c339afdc75b284725359f07b9f99dca188994"
set "AFTER=ab6b3258965d05f745e8897fc7219c9775580ace"
rem after = main at ab6b3258 (hit timing, numbers clear of the name plate, the clean shield collapse from PR 1170), pinned
if "%LB_SHIPS%"=="" set "LB_SHIPS=%VT%\build\godot"
set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%H%" mkdir "%H%"
set "ST=%H%\status.txt"
echo shots1211 run6 start %date% %time% > "%ST%"
rem Artoo (1077, PR 1231): every Godot start goes through the canonical watchdog, tools_live's current version (named in
rem tools_live\current.txt), never a build or clone copy. Its path and both hashes go in the status file.
set "TLV="
if exist "%VT%\tools_live\current.txt" set /p TLV=<"%VT%\tools_live\current.txt"
if not defined TLV (echo FAILED: tools_live\current.txt is missing or empty >> "%ST%" & goto done)
set "TMO=%VT%\tools_live\%TLV%\pc\tmo.bat"
if not exist "%TMO%" (echo FAILED: no watchdog at %TMO% >> "%ST%" & goto done)
if not exist "%VT%\tools_live\%TLV%\pc\run_timeout.ps1" (echo FAILED: no run_timeout.ps1 beside %TMO% >> "%ST%" & goto done)
echo watchdog %TMO% >> "%ST%"
certutil -hashfile "%TMO%" SHA256 >> "%ST%" 2>&1
certutil -hashfile "%VT%\tools_live\%TLV%\pc\run_timeout.ps1" SHA256 >> "%ST%" 2>&1
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%H%\git.txt" 2>&1
git -C "%R%" fetch origin main >> "%H%\git.txt" 2>&1
rem the capture script comes from the pinned after commit (PR 1256 is in it)
git -C "%R%" show %AFTER%:godot/bench/hit_timing_capture.gd > "%H%\hit_timing_capture.gd"
findstr /c:"VS_REAL_APPDATA" "%H%\hit_timing_capture.gd" > nul
if errorlevel 1 (
  echo FAILED: no run 3+ capture script at %AFTER% >> "%ST%"
  goto done
)
call :one after %AFTER%
call :one before %BEFORE%
echo shots1211 done %date% %time% >> "%ST%"
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
if exist "%LB_SHIPS%\gen" robocopy "%LB_SHIPS%\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if exist "%LB_SHIPS%\assets\ships" robocopy "%LB_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if not exist "%R%\godot\.godot" if exist "%LB_SHIPS%\.godot" robocopy "%LB_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
copy /y "%H%\hit_timing_capture.gd" "%R%\godot\bench\hit_timing_capture.gd" > nul
set "PICTURE_SOURCE_REPO=%R%"
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%O%\import.txt" 2>&1
for %%C in (nebula clear) do (
  for %%S in (1920x1080 3840x2160) do call :cap %%C %%S
)
call :cap nebula 1280x720 clip
git -C "%R%" checkout -f --detach %REF% > nul 2>&1
exit /b 0

rem ---- :cap CASE SIZE [clip]: one capture in its own throwaway profile (APPDATA), so your own settings and saves are
rem never opened for writing; the hashes of your real options and settings files are compared before and after.
:cap
set "CK=%~1_%~2%~3_gun_shield"
set "P=%H%\profile\%NAME%_%CK%"
if not exist "%P%" mkdir "%P%"
call :hashes "%O%\real_before_%CK%.txt"
set "OLDAPP=%APPDATA%"
set "VS_REAL_APPDATA=%APPDATA%"
set "OLDLOC=%LOCALAPPDATA%"
set "APPDATA=%P%"
set "LOCALAPPDATA=%P%"
set "VS_CAPTURE_PROFILE=%P%"
set "MOVIE="
set "OUTC=%O%"
if "%~3"=="clip" set "MOVIE=--write-movie "%O%\clip_nebula_720_gun_shield.avi""
if "%~3"=="clip" set "OUTC=%O%\clip"
call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution %~2 %MOVIE% --script res://bench/hit_timing_capture.gd -- --out "%OUTC%" --case %~1 --size %~2 --shot gun --shield > "%O%\log_%CK%.txt" 2>&1
set "APPDATA=%OLDAPP%"
set "LOCALAPPDATA=%OLDLOC%"
set "VS_CAPTURE_PROFILE="
set "VS_REAL_APPDATA="
findstr /c:"HIT_CAPTURE_DONE" "%O%\log_%CK%.txt" >> "%ST%" || findstr /c:"HIT_CAPTURE_SKIPPED" "%O%\log_%CK%.txt" >> "%ST%" || echo FAILED: %NAME% %CK%, see %O%\log_%CK%.txt >> "%ST%"
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
