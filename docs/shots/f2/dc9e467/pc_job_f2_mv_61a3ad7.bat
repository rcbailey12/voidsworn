@echo off
rem F2 movement before and after (feel pass, Nov 1), lane A (about 15 min): the s9 fleet's biggest and smallest ship each make
rem their longest move with turns (--maneuver long), a JPG per frame at 30 fps, 1600x900, HUD hidden. Same code (61a3ad7) both times:
rem before = --movement segments (the shipped motion and pace, kept as a switch), after = the new default.
if not exist godot\project.godot (
  echo not in build
  exit /b 1
)
set /p G=<..\godot_path.txt
set "S=%CD%\..\shots\f2_mv_61a3ad7"
if not exist "%S%" mkdir "%S%"
for %%D in (audio campaign fx main portraits render rules scenes story ui world) do if exist godot\%%D rmdir /s /q godot\%%D
tar -xf f2_mv_61a3ad7_src.zip -C godot
call tools\pc\tmo.bat 900 "%G%" --headless --path godot --import > "%S%\import.txt" 2>&1
call tools\pc\tmo.bat 420 "%G%" --path godot --windowed --resolution 1600x900 --fixed-fps 30 -- --scenario s9 --move-frames "%S%\before" --maneuver long --movement segments --move-trace --speed-trace --window 1600x900 --quit-after 400 > "%S%\before_log.txt" 2>&1
findstr /c:"[moves]" /c:"[move]" "%S%\before_log.txt"
call tools\pc\tmo.bat 420 "%G%" --path godot --windowed --resolution 1600x900 --fixed-fps 30 -- --scenario s9 --move-frames "%S%\after" --maneuver long --move-trace --speed-trace --window 1600x900 --quit-after 400 > "%S%\after_log.txt" 2>&1
findstr /c:"[moves]" /c:"[move]" "%S%\after_log.txt"
for %%P in (before after) do for /d %%X in ("%S%\%%P\*") do tar -a -cf "%S%\%%P_%%~nxX.zip" -C "%S%\%%P" %%~nxX
dir "%S%"
echo done
exit /b 0
