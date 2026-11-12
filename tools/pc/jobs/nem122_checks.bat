@echo off
rem Issue #122 PC checks for the board (R135). Run from the root of a clone made with core.autocrlf=false (LOOP Known traps).
rem   tools\pc\jobs\nem122_checks.bat [path to a clone at opus/issue-121 for the pre-build captures]
rem 1 rules and campaign parity (tools\pc\parity.bat nopause); 2 the Nemesis scenarios, JS against Godot, line by line;
rem 3 the Godot clash twin; 4 the Nemesis panel captures (after; before too when a #121 clone is given).
rem Output: ..\shots\nem122\ (summary.txt, logs, after\*.png, before\*.png)
setlocal
set "ROOT=%CD%\"
set "NODE=node"
if exist "%ROOT%..\node\node.exe" set "NODE=%ROOT%..\node\node.exe"
set /p G=<"%ROOT%..\godot_path.txt"
set "OUT=%ROOT%..\shots\nem122"
if not exist "%OUT%\after" mkdir "%OUT%\after"
set "S=%OUT%\summary.txt"
echo Issue 122 checks, %date% %time% > "%S%"
call "%ROOT%tools\pc\parity.bat" nopause > "%OUT%\parity_log.txt" 2>&1
findstr /b /c:"PASS" /c:"FAIL" "%OUT%\parity_log.txt" >> "%S%"
"%NODE%" "%ROOT%godot\campaign\test\node\nem_scenarios.js" "%OUT%\nem_js.txt" > "%OUT%\nem_js_log.txt" 2>&1
"%G%" --headless --path "%ROOT%godot" --script res://campaign/test/nem_scenarios.gd -- "%OUT%\nem_gd.txt" > "%OUT%\nem_gd_log.txt" 2>&1
fc /b "%OUT%\nem_js.txt" "%OUT%\nem_gd.txt" > nul && (echo PASS: Nemesis scenarios identical >> "%S%") || (echo FAIL: Nemesis scenarios differ, see nem_js.txt and nem_gd.txt >> "%S%")
"%NODE%" "%ROOT%contrib\opus\tools\nemesis_clash_tests.js" "%OUT%\clash.json" >> "%S%" 2>&1
"%G%" --headless --path "%ROOT%godot" --script res://campaign/test/nemesis_clash_test.gd -- "%OUT%\clash.json" > "%OUT%\clash_gd_log.txt" 2>&1
findstr /c:"PASS" /c:"FAIL" "%OUT%\clash_gd_log.txt" >> "%S%"
"%G%" --path "%ROOT%godot" --resolution 1920x1080 --script res://campaign/test/nem_panel_shots.gd -- "%OUT%\after" --no-tips > "%OUT%\shots_after_log.txt" 2>&1
findstr /c:"shot " "%OUT%\shots_after_log.txt" >> "%S%"
if "%~1"=="" goto :done
if not exist "%OUT%\before" mkdir "%OUT%\before"
copy /y "%ROOT%godot\campaign\test\nem_panel_shots.gd" "%~1\godot\campaign\test\nem_panel_shots.gd" > nul
"%G%" --path "%~1\godot" --resolution 1920x1080 --script res://campaign/test/nem_panel_shots.gd -- "%OUT%\before" --no-tips > "%OUT%\shots_before_log.txt" 2>&1
findstr /c:"shot " "%OUT%\shots_before_log.txt" >> "%S%"
:done
echo done >> "%S%"
exit /b 0
