@echo off
rem Issue 209 round 3 on Ryan's PC (Opus worker thread): build and bake the two round 3 cells (Ab3, Hy3) on the 5080, render them,
rem export each with its hand LOD chain, and run the Godot cost bench (20 copies; LOD off, Godot auto LOD, hand chain; 1080p and 3D
rem at 4K), with round 2's Ab as the reference. One GPU job at a time, all in sequence. Started by pc\r3_queue.bat in its own window.
rem Writes Downloads\voidsworn_test\opus209\out3\. Reads round 1's generations (gen\3d) and B0 (bakeoff); deletes nothing.
set V=%USERPROFILE%\Downloads\voidsworn_test
set O=%V%\opus209
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set R=%O%\repo\tools\blender\r209
set OUT=%O%\out3
set G=%O%\gen\3d
set B0=%V%\bakeoff\C15s_23_trellis.glb
if not exist "%OUT%\r" mkdir "%OUT%\r"
if not exist "%OUT%\glb" mkdir "%OUT%\glb"
if not exist "%OUT%\godot\proj" mkdir "%OUT%\godot\proj"
echo start %date% %time% > "%OUT%\time.txt"
cd /d "%O%\repo"
git log -1 --oneline > "%OUT%\git.txt" 2>&1
"%B%" -b -P "%R%\bakeAb3.py" -- "%OUT%" "%B0%" "%G%" Ab3 4096 64 > "%OUT%\log_Ab3.txt" 2>&1
echo Ab3 %date% %time% >> "%OUT%\time.txt"
"%B%" -b -P "%R%\bakeAb3.py" -- "%OUT%" "%B0%" "%G%" Hy3 4096 64 > "%OUT%\log_Hy3.txt" 2>&1
echo Hy3 %date% %time% >> "%OUT%\time.txt"
for %%C in (Ab3 Hy3) do if exist "%OUT%\%%C.blend" "%B%" -b "%OUT%\%%C.blend" -P "%R%\render.py" -- "%OUT%\r" %%C > "%OUT%\logr_%%C.txt" 2>&1
echo rendered %date% %time% >> "%OUT%\time.txt"
for %%C in (Ab3 Hy3) do if exist "%OUT%\%%C.blend" "%B%" -b "%OUT%\%%C.blend" -P "%R%\export3.py" -- "%OUT%\glb\%%C.glb" > "%OUT%\logx_%%C.txt" 2>&1
if exist "%O%\out2\glb\Ab.glb" copy /y "%O%\out2\glb\Ab.glb" "%OUT%\glb\Ab.glb" > nul
echo exported %date% %time% >> "%OUT%\time.txt"
copy /y "%R%\godot\project.godot" "%OUT%\godot\proj\" > nul
copy /y "%R%\godot\bench209r3.gd" "%OUT%\godot\proj\" > nul
"%GD%" --headless --path "%OUT%\godot\proj" --script res://bench209r3.gd --check-only > "%OUT%\log_godot_parse.txt" 2>&1
"%GD%" --path "%OUT%\godot\proj" --resolution 1920x1080 --position -2400,-1400 --script res://bench209r3.gd -- "%OUT%\glb" "%OUT%\godot" Ab,Ab3,Hy3 2 > "%OUT%\log_godot.txt" 2>&1
echo godot %date% %time% >> "%OUT%\time.txt"
echo done > "%OUT%\done.txt"
