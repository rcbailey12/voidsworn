@echo off
rem Issue 1211 pictures for Ryan: one enemy volley (miss, miss, hit) at your ship, in a nebula and in clear space,
rem at 1080p and 4K, on main (before) and on opus/issue-1211 (after), plus a short 1080p nebula clip of each.
rem Its own clone in Downloads\voidsworn_test\opus1211; hulls copied in from the audit2 checkout (copy only).
rem Nothing on the PC is deleted. Each Godot run goes through tmo.bat, so the GPU slots are respected.
rem Output: Downloads\voidsworn_test\opus1211\shots\<before|after>\  and status.txt beside them.
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus1211"
set "R=%H%\repo"
set "BR=opus/issue-1211"
if "%LB_SHIPS%"=="" set "LB_SHIPS=%VT%\audit2\repo\godot"
set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "TMO=%VT%\tools\pc\tmo.bat"
if not exist "%TMO%" set "TMO=%R%\tools\pc\tmo.bat"
if not exist "%H%" mkdir "%H%"
set "ST=%H%\status.txt"
echo shots1211 start %date% %time% > "%ST%"
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%H%\git.txt" 2>&1
git -C "%R%" fetch origin main %BR% >> "%H%\git.txt" 2>&1
git -C "%R%" show origin/%BR%:godot/bench/hit_timing_capture.gd > "%H%\hit_timing_capture.gd"
if errorlevel 1 (
  echo FAILED: no capture script on %BR% >> "%ST%"
  goto done
)
call :one after origin/%BR%
call :one before origin/main
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
  for %%S in (1920x1080 3840x2160) do (
    call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution %%S --script res://bench/hit_timing_capture.gd -- --out "%O%" --case %%C > "%O%\log_%%C_%%S.txt" 2>&1
    findstr /c:"HIT_CAPTURE_DONE" "%O%\log_%%C_%%S.txt" >> "%ST%" || echo FAILED: %NAME% %%C %%S, see %O%\log_%%C_%%S.txt >> "%ST%"
  )
)
call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 --write-movie "%O%\clip_nebula_1080.avi" --script res://bench/hit_timing_capture.gd -- --out "%O%\clip" --case nebula > "%O%\log_clip.txt" 2>&1
if exist "%O%\clip_nebula_1080.avi" (echo clip %NAME% ok >> "%ST%") else (echo clip %NAME% missing, see %O%\log_clip.txt >> "%ST%")
git -C "%R%" checkout -f --detach %REF% > nul 2>&1
exit /b 0
