@echo off
rem Issue 209 round 4, second PC run: the B0 cavity fix (black AO texels as misses) and the fore drum tails off the break line.
rem Bake, render and export only; the Godot numbers come from the first run (out4), the geometry differs only in two drum tails (0.008 of the ship length).
rem Issue 209 round 4 on Ryan's PC (Opus worker thread): build and bake the two round 4 cells (Ab4, Hy4) on the 5080 from the round 4
rem slab structure (armA4.py, silhouette first), render them with round 3's cameras and lights, export each with its hand LOD chain,
rem and run the Godot cost bench with round 3's Ab3 and Hy3 beside them. One GPU job at a time, in sequence. Started by
rem pc\r4_queue.bat in its own window. Writes Downloads\voidsworn_test\opus209\out4\. Reads round 1's generations (gen\3d), B0
rem (bakeoff) and round 3's glbs (out3c\glb); deletes nothing.
set V=%USERPROFILE%\Downloads\voidsworn_test
set O=%V%\opus209
set B=%V%\blender\blender-4.5.14-windows-x64\blender.exe
set GD=%V%\godot\Godot_v4.7.2-stable_win64_console.exe
set R=%O%\repo\tools\blender\r209
set OUT=%O%\out4b
set G=%O%\gen\3d
set B0=%V%\bakeoff\C15s_23_trellis.glb
if not exist "%OUT%\r" mkdir "%OUT%\r"
if not exist "%OUT%\glb" mkdir "%OUT%\glb"
if not exist "%OUT%\godot\proj" mkdir "%OUT%\godot\proj"
echo start %date% %time% > "%OUT%\time.txt"
cd /d "%O%\repo"
git log -1 --oneline > "%OUT%\git.txt" 2>&1
"%B%" -b -P "%R%\bakeAb4.py" -- "%OUT%" "%B0%" "%G%" Ab4 4096 64 > "%OUT%\log_Ab4.txt" 2>&1
echo Ab4 %date% %time% >> "%OUT%\time.txt"
"%B%" -b -P "%R%\bakeAb4.py" -- "%OUT%" "%B0%" "%G%" Hy4 4096 64 > "%OUT%\log_Hy4.txt" 2>&1
echo Hy4 %date% %time% >> "%OUT%\time.txt"
for %%C in (Ab4 Hy4) do if exist "%OUT%\%%C.blend" "%B%" -b "%OUT%\%%C.blend" -P "%R%\render.py" -- "%OUT%\r" %%C > "%OUT%\logr_%%C.txt" 2>&1
echo rendered %date% %time% >> "%OUT%\time.txt"
for %%C in (Ab4 Hy4) do if exist "%OUT%\%%C.blend" "%B%" -b "%OUT%\%%C.blend" -P "%R%\export3.py" -- "%OUT%\glb\%%C.glb" > "%OUT%\logx_%%C.txt" 2>&1
echo exported %date% %time% >> "%OUT%\time.txt"
echo done > "%OUT%\done.txt"
