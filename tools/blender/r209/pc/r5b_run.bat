@echo off
rem Issue 209 round 5, second PC run: the hull knots squared up by hand (no ripple: one midship side line, a smooth belly, monotone
rem bow knots), smooth cubic hull between knots, bow plates following the tuned deck, the casemates and aft drums re-placed on the
rem score. Hy4's close-ups come from the first run (out5\close). Otherwise as the first run:
rem Issue 209 round 5 on Ryan's PC (Opus worker thread): build and bake Ab5 on the 5080 (armA5.py: the hull traced from B0 and tuned
rem to the concept outline, tune5_P.json; hand-rebuilt casemates and drum racks; the tall antenna tower and the aft sensor mast),
rem render it with round 4's cameras and lights, export it with the hand LOD chain, render the casemate and drum rack close-ups of
rem Ab5 and of round 4's Hy4 (its generated parts), and run the Godot cost bench with Ab4 and Hy4 beside it. One GPU job at a time.
rem Started by pc\r5b_queue.bat in its own window. Writes Downloads\voidsworn_test\opus209\out5b\. Reads B0 (bakeoff), round 4's
rem Hy4.blend (out4b) and round 4's glbs (out4\glb); deletes nothing.
set V=%USERPROFILE%\Downloads\voidsworn_test
set O=%V%\opus209
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set R=%O%\repo\tools\blender\r209
set OUT=%O%\out5b
set G=%O%\gen\3d
set B0=%V%\bakeoff\C15s_23_trellis.glb
if not exist "%OUT%\r" mkdir "%OUT%\r"
if not exist "%OUT%\glb" mkdir "%OUT%\glb"
if not exist "%OUT%\close" mkdir "%OUT%\close"
if not exist "%OUT%\godot\proj" mkdir "%OUT%\godot\proj"
echo start %date% %time% > "%OUT%\time.txt"
cd /d "%O%\repo"
git log -1 --oneline > "%OUT%\git.txt" 2>&1
"%B%" -b -P "%R%\bakeAb5.py" -- "%OUT%" "%B0%" "%G%" Ab5 4096 64 > "%OUT%\log_Ab5.txt" 2>&1
echo Ab5 %date% %time% >> "%OUT%\time.txt"
if exist "%OUT%\Ab5.blend" "%B%" -b "%OUT%\Ab5.blend" -P "%R%\render.py" -- "%OUT%\r" Ab5 > "%OUT%\logr_Ab5.txt" 2>&1
echo rendered %date% %time% >> "%OUT%\time.txt"
if exist "%OUT%\Ab5.blend" "%B%" -b "%OUT%\Ab5.blend" -P "%R%\close5.py" -- "%OUT%\close" Ab5 cplate01 srack1frame > "%OUT%\logc_Ab5.txt" 2>&1
echo close %date% %time% >> "%OUT%\time.txt"
if exist "%OUT%\Ab5.blend" "%B%" -b "%OUT%\Ab5.blend" -P "%R%\export3.py" -- "%OUT%\glb\Ab5.glb" > "%OUT%\logx_Ab5.txt" 2>&1
for %%C in (Ab4 Hy4) do copy /y "%O%\out4\glb\%%C.glb" "%OUT%\glb\%%C.glb" > nul
for %%C in (Ab4 Hy4) do copy /y "%O%\out4\glb\%%C_lods.json" "%OUT%\glb\%%C_lods.json" > nul
echo exported %date% %time% >> "%OUT%\time.txt"
copy /y "%R%\godot\project.godot" "%OUT%\godot\proj\" > nul
copy /y "%R%\godot\bench209r3.gd" "%OUT%\godot\proj\" > nul
"%GD%" --path "%OUT%\godot\proj" --resolution 1920x1080 --position -2400,-1400 --script res://bench209r3.gd -- "%OUT%\glb" "%OUT%\godot" Ab4,Hy4,Ab5 2 > "%OUT%\log_godot.txt" 2>&1
echo godot %date% %time% >> "%OUT%\time.txt"
echo done > "%OUT%\done.txt"
