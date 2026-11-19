@echo off
rem Issue 1217 front-end pictures with the live title battle (built ships), for Ryan via the Board (R334).
rem Usage: OPUS1217_FRONTEND.bat [branch]   default branch opus/issue-1217-p4 (phases 2 to 4: title, desk, flagship podium).
rem Its own clone in Downloads\voidsworn_test\opus1217\repo; built ships copied in from the audit2 checkout (copy only,
rem robocopy without purge). Nothing on the PC is deleted. Each Godot run goes through tmo.bat, so the GPU slots hold.
rem Runs godot/ui/test/front_end_shots.gd (title, Settings drawer, Credits drawer at Normal and Larger, the setup desk
rem and the flagship podium) at 1920x1080 and 3840x2160. Output: Downloads\voidsworn_test\opus1217\shots\<1080|2160>\ and status.txt.
setlocal enabledelayedexpansion
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus1217"
set "R=%H%\repo"
set "BR=%~1"
if "%BR%"=="" set "BR=opus/issue-1217-p4"
if "%LB_SHIPS%"=="" set "LB_SHIPS=%VT%\audit2\repo\godot"
set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
set "TMO=%VT%\tools\pc\tmo.bat"
if not exist "%TMO%" set "TMO=%R%\tools\pc\tmo.bat"
if not exist "%H%" mkdir "%H%"
set "ST=%H%\status.txt"
echo opus1217 frontend start %date% %time% branch %BR% > "%ST%"
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%" > "%H%\git.txt" 2>&1
git -C "%R%" fetch origin %BR% >> "%H%\git.txt" 2>&1
git -C "%R%" checkout -f --detach FETCH_HEAD >> "%H%\git.txt" 2>&1
if errorlevel 1 (
  echo FAILED: cannot check out %BR% >> "%ST%"
  goto done
)
for /f %%C in ('git -C "%R%" rev-parse HEAD') do set "COMMIT=%%C"
echo commit !COMMIT! >> "%ST%"
if exist "%LB_SHIPS%\gen" robocopy "%LB_SHIPS%\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if exist "%LB_SHIPS%\assets\ships" robocopy "%LB_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
if not exist "%R%\godot\.godot" if exist "%LB_SHIPS%\.godot" robocopy "%LB_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > nul 2>&1
set "PICTURE_SOURCE_REPO=%R%"
call "%TMO%" 1800 "%G%" --headless --path "%R%\godot" --import > "%H%\import.txt" 2>&1
for %%S in (1920x1080 3840x2160) do (
  set "SZ=%%S"
  set "O=%H%\shots\!SZ:~-4!"
  if not exist "!O!" mkdir "!O!"
  call "%TMO%" 900 "%G%" --path "%R%\godot" --rendering-method forward_plus --windowed --resolution %%S --script res://ui/test/front_end_shots.gd -- "!O!" "!COMMIT:~0,8!" > "!O!\log.txt" 2>&1
  findstr /c:"front-end-shots" "!O!\log.txt" >> "%ST%" || echo FAILED: %%S, see !O!\log.txt >> "%ST%"
)
echo opus1217 frontend done %date% %time% >> "%ST%"
:done
type "%ST%"
exit /b 0
