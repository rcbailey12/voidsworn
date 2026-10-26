@echo off
rem G2 checks: the hull lineup (every hull flat at facing 0, top, side, three-quarter) and 20 headless bot battles.
rem Queue job: runs from Downloads\voidsworn_test\build. Output: ..\shots\g2_lineup\*.png and ..\shots\g2_bot\report.json
setlocal
set "ROOT=%CD%\"
set /p G=<"%ROOT%..\godot_path.txt"
set "TMO=%ROOT%tools\pc\tmo.bat"
set "OUT=%ROOT%..\shots"
if not exist "%OUT%\g2_lineup" mkdir "%OUT%\g2_lineup"
if not exist "%OUT%\g2_bot" mkdir "%OUT%\g2_bot"
if not exist "%ROOT%godot\gen\v3.txt" call "%TMO%" 1800 "%G%" --headless --path "%ROOT%godot" --script res://render/build_assets.gd -- --repo "%ROOT%." --hi "%ROOT%..\enginetest\assets\hi" --env "%ROOT%..\enginetest\assets\env" > "%OUT%\g2_bot\build_assets_log.txt" 2>&1
call "%TMO%" 1800 "%G%" --path "%ROOT%godot" --rendering-method forward_plus --resolution 2560x1440 res://scenes/battle/lineup.tscn -- --out "%OUT%\g2_lineup" > "%OUT%\g2_lineup\log.txt" 2>&1
call "%TMO%" 1800 "%G%" --headless --path "%ROOT%godot" -- --bot-runs 20 --fast 40 --report "%OUT%\g2_bot\report.json" > "%OUT%\g2_bot\log.txt" 2>&1
echo done
exit /b 0
