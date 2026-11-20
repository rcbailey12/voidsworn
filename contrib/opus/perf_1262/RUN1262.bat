@echo off
rem Issue 1262: cheaper 4K Max, timed and pictured on the RTX 5080 (Board queue job; GPU solo, R293).
rem Own clone in Downloads\voidsworn_test\opus1262\repo on opus/issue-1262; built ships copied in from
rem Downloads\voidsworn_test\build\godot (copy only). Six timing variants x 3 sessions, then old and new pictures.
rem Results: opus1262\repo\run\summary1262.txt, timings in run\t1262_*, pictures in run\s1262_old and run\s1262_new.
rem Nothing is deleted. A rerun refuses if run\ already holds a 1262 output (rename it first).
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus1262"
set "R=%H%\repo"
set "BR=opus/issue-1262"
if "%LB_SHIPS%"=="" set "LB_SHIPS=%VT%\build\godot"
if not exist "%H%" mkdir "%H%"
if not exist "%R%\.git" git -c core.autocrlf=false clone https://github.com/rcbailey12/voidsworn "%R%"
git -C "%R%" fetch origin %BR% || (echo FAILED: git fetch & exit /b 1)
git -C "%R%" checkout -f -B %BR% origin/%BR% || (echo FAILED: checkout & exit /b 1)
if exist "%LB_SHIPS%\gen" robocopy "%LB_SHIPS%\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul
if exist "%LB_SHIPS%\assets\ships" robocopy "%LB_SHIPS%\assets\ships" "%R%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul
if not exist "%R%\godot\.godot" if exist "%LB_SHIPS%\.godot" robocopy "%LB_SHIPS%\.godot" "%R%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > nul
set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
call "%R%\tools\pc\tmo.bat" 1800 "%G%" --headless --path "%R%\godot" --import > "%H%\import.txt" 2>&1
if errorlevel 1 (echo FAILED: import, see %H%\import.txt & exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -File "%R%\contrib\opus\perf_1262\run1262.ps1" -Work "%R%"
if errorlevel 1 (echo FAILED: see the output above & exit /b 1)
start "" "%R%\run"
exit /b 0
