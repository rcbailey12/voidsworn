@echo off
rem Issue 1204 (Opus helper, PR 1216): the PC proof for "clear every GPU static at quit, one mesh watcher".
rem 1. a 5-run headless bot campaign on the branch with the PC-built hulls: exit code 0, 0 errors, no access violation at exit
rem 2. the look bench, branch against main: the sheets should show no change
rem Copies only. Its own folder Downloads\voidsworn_test\opus1204\. Nothing is deleted.
setlocal
set "VT=%USERPROFILE%\Downloads\voidsworn_test"
set "H=%VT%\opus1204"
set "C=%H%\repo"
set "SHIPS=%VT%\audit2\repo\godot"
if not exist "%H%" mkdir "%H%"
set /p G=<"%VT%\godot_path.txt"
if "%G%"=="" set "G=%VT%\godot\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%C%\.git" git clone -q --depth 20 -b opus/issue-1204 https://github.com/rcbailey12/voidsworn "%C%"
git -C "%C%" fetch -q --depth 20 origin opus/issue-1204
git -C "%C%" checkout -q -f -B run1204 FETCH_HEAD
git -C "%C%" rev-parse HEAD > "%H%\commit.txt"
if exist "%SHIPS%\gen" robocopy "%SHIPS%\gen" "%C%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul
if exist "%SHIPS%\assets\ships" robocopy "%SHIPS%\assets\ships" "%C%\godot\assets\ships" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1 > nul
if not exist "%C%\godot\.godot" if exist "%SHIPS%\.godot" robocopy "%SHIPS%\.godot" "%C%\godot\.godot" /E /NFL /NDL /NJH /NJS /R:1 /W:1 > nul
"%G%" --headless --path "%C%\godot" --import > "%H%\import_log.txt" 2>&1
echo bot runs started %DATE% %TIME% > "%H%\result.txt"
call "%C%\tools\pc\tmo.bat" 3600 "%G%" --headless --path "%C%\godot" -- --bot-runs 5 --fast 40 --seed 359 --report "%H%\bot_report.json" > "%H%\bot_log.txt" 2>&1
set "CODE=%ERRORLEVEL%"
echo bot runs exit code %CODE% (0 is clean; -1073741819 is the old access violation) >> "%H%\result.txt"
findstr /C:"SUMMARY" /C:"leaked" /C:"still in use" /C:"SCRIPT ERROR" "%H%\bot_log.txt" >> "%H%\result.txt"
echo look bench started %DATE% %TIME% >> "%H%\result.txt"
call "%VT%\look_bench.bat" origin/opus/issue-1204 origin/main
echo done %DATE% %TIME% >> "%H%\result.txt"
endlocal
