@echo off
rem A4: refresh the Godot build's converted ships (godot\gen\ships, gen\damage, gen\wreck) after A4 ship jobs re-export them.
rem build_assets.gd rebuilds only the ships whose glb files changed (time or size), but play_godot.bat and g2_export.bat skip the
rem whole step once gen\v3.txt exists, so re-exported ships were never picked up (G4, Oct 31). Queue this after a batch of ship jobs.
rem Queue job from Downloads\voidsworn_test\build (stage.py --regen writes it). Log: voidsworn_test\a4\regen_log.txt
setlocal
set "ROOT=%CD%\"
set /p G=<"%ROOT%..\godot_path.txt"
set "LOG=%USERPROFILE%\Downloads\voidsworn_test\a4\regen_log.txt"
echo regen %date% %time% > "%LOG%"
call tools\pc\tmo.bat 1100 "%G%" --headless --path "%ROOT%godot" --script res://render/build_assets.gd -- --repo "%ROOT%." --hi "%ROOT%..\enginetest\assets\hi" --env "%ROOT%..\enginetest\assets\env" --max-seconds 900 >> "%LOG%" 2>&1
type "%LOG%" | findstr /l /c:"[assets]" /c:"ERROR" /c:"out of time"
endlocal
exit /b
